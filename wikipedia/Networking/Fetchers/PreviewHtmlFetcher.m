//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PreviewHtmlFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"

@implementation PreviewHtmlFetcher

-(instancetype)initAndFetchHtmlForWikiText: (NSString *)wikiText
                                     title: (NSString *)title
                                    domain: (NSString *)domain
                               withManager: (AFHTTPRequestOperationManager *)manager
                        thenNotifyDelegate: (id <FetchFinishedDelegate>) delegate
{
    self = [super init];
    if (self) {
        self.fetchFinishedDelegate = delegate;
        [self fetchPreviewForWikiText:wikiText title:title domain:domain withManager:manager];
    }
    return self;
}

- (void)fetchPreviewForWikiText: (NSString *)wikiText
                          title: (NSString *)title
                         domain: (NSString *)domain
                    withManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForDomain:domain];

    NSDictionary *params = [self getParamsForTitle:title wikiText:wikiText];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    // Note: "Preview should probably stay as a post, since the wikitext chunk may be
    // pretty long and there may or may not be a limit on URL length some" - Brion
    [manager POST:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Preview not found."}};
        }
        
        //NSLog(@"PREVIEW HTML DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Preview HTML Fetcher" code:001 userInfo:errorDict];
        }

        NSString *output = @"";
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        [self finishWithError: error
                     userData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"PREVIEW HTML FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                     userData: nil];
    }];
}

-(NSDictionary *)getParamsForTitle:(NSString *)title wikiText:(NSString *)wikiText
{
    return @{
             @"action": @"parse",
             @"sectionpreview": @"true",
             @"pst": @"true",
             @"mobileformat": @"true",
             @"title": (title ? title : @""),
             @"prop": @"text",
             @"text": (wikiText ? wikiText : @""),
             @"format": @"json"
             }.mutableCopy;
}

-(NSString *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    if(![rawResponse isDict]) return @"";

    id parse = rawResponse[@"parse"];
    
    if(![parse isDict]) return @"";

    id text = parse[@"text"];
    
    if(![text isDict]) return @"";

    NSString *result = text[@"*"];

    return (result ? result : @"");
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING PAGE HISTORY FETCHER!");
}
*/

@end
