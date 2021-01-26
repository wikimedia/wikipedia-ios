#import "WMFArticleRevisionFetcher.h"
@import WMF.NSURL_WMFLinkParsing;
#import "WMFRevisionQueryResults.h"
#import "WMFArticleRevision.h"
#import "Wikipedia-Swift.h"

@implementation WMFArticleRevisionFetcher

- (NSURLSessionTask *)fetchLatestRevisionsForArticleURL:(NSURL *)articleURL
                                            resultLimit:(NSUInteger)numberOfResults
                                   startingWithRevision:(NSNumber *)startRevisionId
                                     endingWithRevision:(NSNumber *)endRevisionId
                                                failure:(WMFErrorHandler)failure
                                                success:(WMFSuccessIdHandler)success {
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                        @"format": @"json",
                                                                                        @"continue": @"",
                                                                                        @"formatversion": @2,
                                                                                        @"action": @"query",
                                                                                        @"prop": @"revisions",
                                                                                        @"redirects": @1,
                                                                                        @"titles": articleURL.wmf_title,
                                                                                        @"rvlimit": @(numberOfResults),
                                                                                        @"rvprop": [@[@"ids", @"size", @"flags"] componentsJoinedByString:@"|"],
                                                                                        //@"pilicense": @"any"
                                                                                        }];
    
    if (startRevisionId != nil) {
        parameters[@"rvstartid"] = startRevisionId;
    }
    
    if (endRevisionId != nil) {
        parameters[@"rvendid"] = endRevisionId;
    }
    return [self performMediaWikiAPIGETForURL:articleURL withQueryParameters:[parameters copy] completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failure(error);
            return;
        }
        NSError *mantleError = nil;
        NSArray *results = [WMFLegacySerializer modelsOfClass:[WMFRevisionQueryResults class] fromArrayForKeyPath:@"query.pages" inJSONDictionary:result languageVariantCode: articleURL.wmf_languageVariantCode error:&mantleError];
        if (mantleError) {
            failure(mantleError);
            return;
        }
        success([results firstObject]);
    }];
}

@end
