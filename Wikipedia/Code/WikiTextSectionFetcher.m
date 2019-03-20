#import "WikiTextSectionFetcher.h"
#import "NSObject+WMFExtras.h"
@import WMF;

NSString *const WikiTextSectionFetcherErrorDomain = @"org.wikimedia.fetcher.wikitext";

@implementation WikiTextSectionFetcher

- (void)fetchSection:(MWKSection *)section completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    
    NSURL *sourceURL = section.sourceURL;
    NSString *title = sourceURL.wmf_title;
    if (!sourceURL || !title) {
        completion(nil, [WMFFetcher invalidParametersError]);
        return;
    }
    NSDictionary *params = @{
                             @"action": @"query",
                             @"prop": @"revisions",
                             @"rvprop": @"content",
                             @"rvlimit": @1,
                             @"rvsection": section.index ? section.index : @"0",
                             @"titles": title,
                             @"meta": @"userinfo", // we need the local user ID for event logging
                             @"continue": @"",
                             @"format": @"json"
                             };
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];
    
    [self performMediaWikiAPIGETForURL:sourceURL withQueryParameters:params completionHandler:^(NSDictionary<NSString *,id> * _Nullable responseObject, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        if (error) {
            completion(nil, error);
            return;
        }
        
        // Fake out an error if non-dictionary response received.
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            responseObject = @{ @"error": @{@"info": @"Wikitext not found."} };
        }
        
        //NSLog(@"WIKITEXT RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        if (responseObject[@"error"]) {
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:WikiTextSectionFetcherErrorDomain code:WikiTextFetcherErrorTypeAPI userInfo:errorDict];
            completion(nil, error);
            return;
        }
        
        NSDictionary *output = [self getSanitizedResponse:responseObject];
        
        // Handle case where revision or userInfo not retrieved.
        if (![output objectForKey:@"revision"] || ![output objectForKey:@"userInfo"]) {
            NSMutableDictionary *errorDict = @{}.mutableCopy;
            errorDict[NSLocalizedDescriptionKey] = WMFLocalizedStringWithDefaultValue(@"wikitext-download-failed", nil, nil, @"Unable to obtain latest revision.", @"Alert text shown when unable to obtain latest revision of the section being edited");
            error = [NSError errorWithDomain:WikiTextSectionFetcherErrorDomain code:WikiTextFetcherErrorTypeIncomplete userInfo:errorDict];
            completion(nil, error);
            return;
        }
        
        completion(output, nil);
    }];
}

- (NSDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse {
    NSMutableDictionary *output = @{}.mutableCopy;
    if (![rawResponse isDict]) {
        return output;
    }
    
    NSDictionary *query = rawResponse[@"query"];
    if (![query isDict]) {
        return output;
    }
    
    NSDictionary *pages = query[@"pages"];
    NSDictionary *userInfo = query[@"userinfo"];
    if (![pages isDict] || ![userInfo isDict]) {
        return output;
    }
    
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
    
    if (revision) {
        output[@"revision"] = revision;
    }
    if (userInfo) {
        output[@"userInfo"] = userInfo;
    }
    
    return output;
}

/*
 -(void)dealloc
 {
 NSLog(@"DEALLOC'ING PAGE HISTORY FETCHER!");
 }
 */

@end
