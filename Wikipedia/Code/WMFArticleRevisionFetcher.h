#import <Foundation/Foundation.h>

@interface WMFArticleRevisionFetcher : NSObject

- (instancetype)init;

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval;

- (NSURLSessionTask *)fetchLatestRevisionsForArticleURL:(NSURL *)articleURL
                              resultLimit:(NSUInteger)numberOfResults
                       endingWithRevision:(NSUInteger)revisionId
                                  failure:(WMFErrorHandler)failure
                                  success:(WMFSuccessIdHandler)success;

@end
