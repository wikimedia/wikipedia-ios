@import Foundation;
@import WMF.WMFBlockDefinitions;
@import WMF.WMFLegacyFetcher;

@interface WMFArticleRevisionFetcher : WMFLegacyFetcher

//tonitodo: articleTitle was just to get around crashing when forcing wmflabs host. remove when history/diffs move to prod
- (NSURLSessionTask *)fetchLatestRevisionsForArticleURL:(NSURL *)articleURL
                                            articleTitle: (NSString *)articleTitle
                                            resultLimit:(NSUInteger)numberOfResults
                                startingWithRevision:(NSNumber *)startRevisionId
                                     endingWithRevision:(NSNumber *)endRevisionId
                                                failure:(WMFErrorHandler)failure
                                                success:(WMFSuccessIdHandler)success;

@end
