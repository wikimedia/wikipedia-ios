@import Foundation;
@import WMF.WMFBlockDefinitions;
@import WMF.WMFLegacyFetcher;

@interface WMFArticleRevisionFetcher : WMFLegacyFetcher

- (NSURLSessionTask *)fetchLatestRevisionsForArticleURL:(NSURL *)articleURL
                                            resultLimit:(NSUInteger)numberOfResults
                                startingWithRevision:(NSNumber *)startRevisionId
                                     endingWithRevision:(NSNumber *)endRevisionId
                                                failure:(WMFErrorHandler)failure
                                                success:(WMFSuccessIdHandler)success;

@end
