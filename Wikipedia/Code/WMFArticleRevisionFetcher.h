@import Foundation;
@import WMF.WMFBlockDefinitions;
@import WMF.WMFLegacyFetcher;

@interface WMFArticleRevisionFetcher : WMFLegacyFetcher

- (NSURLSessionTask *)fetchLatestRevisionsForArticleURL:(NSURL *)articleURL
                                            resultLimit:(NSUInteger)numberOfResults
                                     endingWithRevision:(NSNumber *)revisionId
                                                failure:(WMFErrorHandler)failure
                                                success:(WMFSuccessIdHandler)success;

@end
