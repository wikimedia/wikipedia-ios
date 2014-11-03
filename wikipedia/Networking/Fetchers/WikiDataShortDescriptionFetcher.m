//  Created by Monte Hurd on 11/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikiDataShortDescriptionFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"

#define WIKIDATA_ENDPOINT @"https://www.wikidata.org/w/api.php"

@interface WikiDataShortDescriptionFetcher()

@property (nonatomic, strong) NSArray *wikiDataIds;
@property (nonatomic, strong) NSString *domain;
@property (nonatomic) SearchType searchType;

@end

@implementation WikiDataShortDescriptionFetcher

-(instancetype)initAndFetchDescriptionsForIds: (NSArray *)wikiDataIds
                                   searchType: (SearchType)searchType
                                  withManager: (AFHTTPRequestOperationManager *)manager
                           thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.searchType = searchType;
        self.wikiDataIds = wikiDataIds;
        self.domain = [SessionSingleton sharedInstance].site.language;
        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
}

- (void)fetchWithManager:(AFHTTPRequestOperationManager *)manager
{
    NSString *url = WIKIDATA_ENDPOINT;

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Convert the raw NSData response to a dictionary.
        if (![self isDataResponseValid:responseObject]){
            // Fake out an error if bad response received.
            responseObject = @{@"error": @{@"info": @"WikiData not found."}};
        }else{
            // Should be able to proceed with dictionary conversion.
            NSError *jsonError = nil;
            responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonError];
            responseObject = jsonError ? @{} : responseObject;
        }
        
        // NSLog(@"\n\nDATA RETRIEVED = %@\n\n", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"WikiData Fetcher"
                                        code: SHORT_DESCRIPTION_ERROR_API
                                    userInfo: errorDict];
        }

        NSMutableDictionary *output = @{}.mutableCopy;
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        // If no matches set error.
        if (output.count == 0) {
            NSMutableDictionary *errorDict = @{}.mutableCopy;
            
            // errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"search-no-matches", nil);
            
            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
            error = [NSError errorWithDomain:@"WikiData Fetcher" code:SHORT_DESCRIPTION_ERROR_NO_MATCHES userInfo:errorDict];
        }

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"CAPTCHA RESETTER FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSDictionary *)getParams
{
    return @{
             @"action": @"wbgetentities",
             @"ids": [self.wikiDataIds componentsJoinedByString:@"|"],
             @"props": @"descriptions",
             @"languages": self.domain,
             @"format": @"json"
             };
}

-(NSMutableDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    // Make output dict mapping wikidata ids to the short descriptions retrieved.
    NSMutableDictionary *output = @{}.mutableCopy;
    if (rawResponse.count > 0) {
        id entities = rawResponse[@"entities"];
        if ([entities isKindOfClass:[NSDictionary class]]) {
            for (id page in entities) {
                id val = entities[page];
                if ([val isKindOfClass:[NSDictionary class]]) {
                    id descriptions = val[@"descriptions"];
                    if ([descriptions isKindOfClass:[NSDictionary class]]) {
                        id thisDescriptionDict = descriptions[self.domain];
                        if ([thisDescriptionDict isKindOfClass:[NSDictionary class]]) {
                            id description = thisDescriptionDict[@"value"];
                            if (description && [description isKindOfClass:[NSString class]]) {
                                output[page] = description;
                            }
                        }
                    }
                }
            }
        }
    }
    
    return output;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING ACCT CREATION TOKEN FETCHER!");
}
*/

@end
