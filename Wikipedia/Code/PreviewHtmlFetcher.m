#import "PreviewHtmlFetcher.h"
#import "NSObject+WMFExtras.h"
@import WMF.MWNetworkActivityIndicatorManager;
@import WMF.NSURL_WMFLinkParsing;

@implementation PreviewHtmlFetcher

- (void)fetchHTMLForWikiText:(NSString *)wikiText articleURL:(NSURL *)articleURL completion:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion {

    NSDictionary *params = [self getParamsForArticleURL:articleURL wikiText:wikiText];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [self performMediaWikiAPIPOSTForURL:articleURL withBodyParameters:params completionHandler:^(NSDictionary<NSString *,id> * _Nullable responseObject, NSHTTPURLResponse * _Nullable response, NSError * _Nullable networkError) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        if (networkError) {
            completion(nil, networkError);
            return;
        }
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
        completion(output, error);
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

@end
