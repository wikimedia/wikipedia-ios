//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RandomArticleFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"

@interface RandomArticleFetcher()

@property (strong, nonatomic) NSString *domain;

@end

@implementation RandomArticleFetcher

-(instancetype)initAndFetchRandomArticleForDomain: (NSString *)domain
                                      withManager: (AFHTTPRequestOperationManager *)manager
                               thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.domain = domain;
        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
}

- (void)fetchWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSString *url = [[SessionSingleton sharedInstance] urlForLanguage:self.domain].absoluteString;

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        
        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Random article data not found."}};
        }

        //NSLog(@"RANDOM ARTICLE RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Random Article Fetcher"
                                        code: RANDOM_ARTICLE_FETCH_ERROR_API
                                    userInfo: errorDict];
        }

        NSString *output = @"";
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"RANDOM ARTICLE FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSDictionary *)getParams
{
    return @{
             @"action": @"query",
             @"list": @"random",
             @"rnlimit": @"1",
             @"rnnamespace": @"0",
             @"format": @"json"
             };
}

-(NSString *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    NSArray *randomArticles = (NSArray *)rawResponse[@"query"][@"random"];
    NSDictionary *article = [randomArticles objectAtIndex:0];
    NSString *title = article[@"title"];
    return title;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING LOGIN TOKEN FETCHER!");
}
*/

@end
