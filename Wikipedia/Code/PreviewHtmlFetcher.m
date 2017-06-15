#import "PreviewHtmlFetcher.h"
@import AFNetworking;
#import "NSObject+WMFExtras.h"
@import WMF.SessionSingleton;
@import WMF.MWNetworkActivityIndicatorManager;
@import WMF.NSURL_WMFLinkParsing;

@implementation PreviewHtmlFetcher

- (instancetype)initAndFetchHtmlForWikiText:(NSString *)wikiText
                                 articleURL:(NSURL *)articleURL
                                withManager:(AFHTTPSessionManager *)manager
                         thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.fetchFinishedDelegate = delegate;
        [self fetchPreviewForWikiText:wikiText articleURL:articleURL withManager:manager];
    }
    return self;
}

- (void)fetchPreviewForWikiText:(NSString *)wikiText
                     articleURL:(NSURL *)articleURL
                    withManager:(AFHTTPSessionManager *)manager {
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:articleURL.wmf_language];

    NSDictionary *params = [self getParamsForArticleURL:articleURL wikiText:wikiText];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    // Note: "Preview should probably stay as a post, since the wikitext chunk may be
    // pretty long and there may or may not be a limit on URL length some" - Brion
    [manager POST:url.absoluteString
        parameters:params
        progress:NULL
        success:^(NSURLSessionDataTask *operation, id responseObject) {
            //NSLog(@"JSON: %@", responseObject);
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            // Fake out an error if non-dictionary response received.
            if (![responseObject isDict]) {
                responseObject = @{ @"error": @{@"info": @"Preview not found."} };
            }

            //NSLog(@"PREVIEW HTML DATA RETRIEVED = %@", responseObject);

            // Handle case where response is received, but API reports error.
            NSError *error = nil;
            if (responseObject[@"error"]) {
                NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                error = [NSError errorWithDomain:@"Preview HTML Fetcher" code:001 userInfo:errorDict];
            }

            NSString *output = @"";
            if (!error) {
                output = [self getSanitizedResponse:responseObject];
            }

            [self finishWithError:error
                      fetchedData:output];
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            //NSLog(@"PREVIEW HTML FAIL = %@", error);

            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            [self finishWithError:error
                      fetchedData:nil];
        }];
}

- (NSDictionary *)getParamsForArticleURL:(NSURL *)articleURL wikiText:(NSString *)wikiText {
    return @{
        @"action": @"parse",
        @"sectionpreview": @"true",
        @"pst": @"true",
        @"mobileformat": @"true",
        @"title": (articleURL.wmf_title ? articleURL.wmf_title : @""),
        @"prop": @"text",
        @"text": (wikiText ? wikiText : @""),
        @"format": @"json"
    }
        .mutableCopy;
}

- (NSString *)getSanitizedResponse:(NSDictionary *)rawResponse {
    if (![rawResponse isDict]) {
        return @"";
    }

    id parse = rawResponse[@"parse"];

    if (![parse isDict]) {
        return @"";
    }

    id text = parse[@"text"];

    if (![text isDict]) {
        return @"";
    }

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
