//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikiTextSectionFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "WikipediaAppUtils.h"
#import "ArticleCoreDataObjects.h"

@interface WikiTextSectionFetcher()

@property (strong, nonatomic) MWKSection *section;

@end

@implementation WikiTextSectionFetcher

-(instancetype)initAndFetchWikiTextForSection: (MWKSection *)section
                                  withManager: (AFHTTPRequestOperationManager *)manager
                           thenNotifyDelegate: (id <FetchFinishedDelegate>) delegate
{
    self = [super init];
    if (self) {
        self.section = section;
        self.fetchFinishedDelegate = delegate;
        [self fetchWikiTextWithManager:manager];
    }
    return self;
}

- (void)fetchWikiTextWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.section.site.language];

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    // Note: "Preview should probably stay as a post, since the wikitext chunk may be
    // pretty long and there may or may not be a limit on URL length some" - Brion
    [manager GET:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Wikitext not found."}};
        }
        
        //NSLog(@"WIKITEXT RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Wikitext Fetcher" code:WIKITEXT_FETCHER_ERROR_API userInfo:errorDict];
        }

        NSDictionary *output = @{};
        if (!error) {
            output = [self getSanitizedResponse:responseObject];

            // Handle case where revision or userInfo not retrieved.
            if (![output objectForKey:@"revision"] || ![output objectForKey:@"userInfo"]) {
                NSMutableDictionary *errorDict = @{}.mutableCopy;
                errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"wikitext-download-failed", nil);
                error = [NSError errorWithDomain:@"Wikitext Fetcher" code:WIKITEXT_FETCHER_ERROR_INCOMPLETE userInfo:errorDict];
            }
        }

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"WIKITEXT DOWNLOAD FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSDictionary *)getParams
{
    return @{
             @"action": @"query",
             @"prop": @"revisions",
             @"rvprop": @"content",
             @"rvlimit": @1,
             @"rvsection": self.section.index,
             @"titles": self.section.fromtitle.prefixedText,
             @"meta": @"userinfo", // we need the local user ID for event logging
             @"format": @"json"
             };
}

-(NSDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    NSMutableDictionary *output = @{}.mutableCopy;
    if(![rawResponse isDict]) return output;

    NSDictionary *query = rawResponse[@"query"];
    if(![query isDict]) return output;

    NSDictionary *pages = query[@"pages"];
    NSDictionary *userInfo = query[@"userinfo"];
    if(![pages isDict] || ![userInfo isDict]) return output;

    NSString *revision = nil;
    if (pages && (pages.allKeys.count > 0)) {
        NSString *key = pages.allKeys[0];
        if (key) {
            NSDictionary *page = pages[key];
            if (page) {
                revision = page[@"revisions"][0][@"*"];
            }
        }
    }

    if (revision) output[@"revision"] = revision;
    if (userInfo) output[@"userInfo"] = userInfo;
    
    return output;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING PAGE HISTORY FETCHER!");
}
*/

@end
