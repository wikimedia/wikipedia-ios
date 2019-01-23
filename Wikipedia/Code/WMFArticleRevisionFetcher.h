@import Foundation;
@import WMF.WMFBlockDefinitions;
@import WMF.WMFFetcher;

@interface WMFArticleRevisionFetcher : WMFFetcher

- (NSURLSessionTask *)fetchLatestRevisionsForArticleURL:(NSURL *)articleURL
                                            resultLimit:(NSUInteger)numberOfResults
                                     endingWithRevision:(NSUInteger)revisionId
                                                failure:(WMFErrorHandler)failure
                                                success:(WMFSuccessIdHandler)success;

@end
