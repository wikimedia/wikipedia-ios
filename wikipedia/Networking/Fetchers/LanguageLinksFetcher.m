//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LanguageLinksFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"

@interface LanguageLinksFetcher()

@property (strong, nonatomic) MWKTitle *title;
@property (strong, nonatomic) NSArray *allLanguages;

@end

@implementation LanguageLinksFetcher

-(instancetype)initAndFetchLanguageLinksForPageTitle: (MWKTitle *)title
                                        allLanguages: (NSArray *)allLanguages
                                         withManager: (AFHTTPRequestOperationManager *)manager
                                  thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {

        self.title = title;
        assert(title != nil);
        self.allLanguages = allLanguages;

        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
}

- (void)fetchWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.title.site.language];

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        
        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Language links not found."}};
        }

        //NSLog(@"LANGUAGE LINKS RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Language Links Fetcher"
                                        code: LANGUAGE_LINKS_FETCH_ERROR_API
                                    userInfo: errorDict];
        }

        NSMutableArray *output = @[].mutableCopy;
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"LANGUAGE LINKS FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSDictionary *)getParams
{
    return @{
             @"action": @"query",
             @"prop": @"langlinks",
             @"titles": self.title.prefixedText,
             @"lllimit": @"500",
             @"redirects": @"",
             @"format": @"json"
             };
}

-(NSMutableArray *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    NSArray *langLinks = @[];
    NSDictionary *pages = rawResponse[@"query"][@"pages"];
    if (pages) {
        NSDictionary *page = pages[pages.allKeys[0]];
        if (page) {
            langLinks = page[@"langlinks"];
        }
    }
    
    // Get dictionary with lang code as key and the localized title as the value
    NSMutableDictionary *langCodeToLocalTitleDict = @{}.mutableCopy;
    for (NSDictionary *d in langLinks) {
        NSString *lang = d[@"lang"];
        NSString *title = d[@"*"];
        if (lang && title) {
            langCodeToLocalTitleDict[lang] = title;
        }
    }
    
    // Loop through the data from the languages file and add an entry to the
    // output array for each match found in langCodeToLocalTitleDict including
    // all of the keys from the lang file and the local title from the downloaded
    // results. The end results is an array containing dictionaries containing
    // the lang code, lang name, lang canonical name, and the localized title.
    // (Also, the output array's lang codes will be ordered the same as they are
    // in the lang file.)
    NSMutableArray *outputArray = @[].mutableCopy;
    for (NSDictionary *fileDict in self.allLanguages) {
        NSString *code = fileDict[@"code"];
        if (code && [langCodeToLocalTitleDict objectForKey:code]) {
            
            if ([[SessionSingleton sharedInstance].unsupportedCharactersLanguageIds indexOfObject:code] != NSNotFound) continue;
            
            NSString *canonicalName = fileDict[@"canonical_name"];
            NSString *name = fileDict[@"name"];
            
            if (canonicalName && name) {
                [outputArray addObject:@{
                                         @"code": code,
                                         @"canonical_name": canonicalName,
                                         @"name": name,
                                         @"*": langCodeToLocalTitleDict[code],
                                         }];
            }
        }
    }
    return outputArray;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING LANGUAGE LINKS FETCHER!");
}
*/

@end
