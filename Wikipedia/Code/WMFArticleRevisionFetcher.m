#import "WMFArticleRevisionFetcher.h"
@import WMF.WMFMantleJSONResponseSerializer;
@import WMF.WMFNetworkUtilities;
@import WMF.NSURL_WMFLinkParsing;
#import "WMFRevisionQueryResults.h"
#import "WMFArticleRevision.h"
#import "Wikipedia-Swift.h"

@implementation WMFArticleRevisionFetcher

- (NSURLSessionTask *)fetchLatestRevisionsForArticleURL:(NSURL *)articleURL
                                            resultLimit:(NSUInteger)numberOfResults
                                     endingWithRevision:(NSUInteger)revisionId
                                                failure:(WMFErrorHandler)failure
                                                success:(WMFSuccessIdHandler)success {
    NSDictionary *parameters = @{
                                 @"format": @"json",
                                 @"continue": @"",
                                 @"formatversion": @2,
                                 @"action": @"query",
                                 @"prop": @"revisions",
                                 @"redirects": @1,
                                 @"titles": articleURL.wmf_title,
                                 @"rvlimit": @(numberOfResults),
                                 @"rvendid": @(revisionId),
                                 @"rvprop": WMFJoinedPropertyParameters(@[@"ids", @"size", @"flags"]) //,
                                 //@"pilicense": @"any"
                                 };
    return [self performMediaWikiAPIGETForURL:articleURL withQueryParameters:parameters completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failure(error);
            return;
        }
        NSError *mantleError = nil;
        NSArray *results = [WMFLegacySerializer modelsOfClass:[WMFRevisionQueryResults class] fromArrayForKeyPath:@"query.pages"  inJSONDictionary:result error:&mantleError];
        if (mantleError) {
            failure(mantleError);
            return;
        }
        success([results firstObject]);
    }];
}

@end
