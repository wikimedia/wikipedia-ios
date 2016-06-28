
#import <Foundation/Foundation.h>

@interface WMFArticleRevisionFetcher : NSObject

- (instancetype)init;

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval;

- (AnyPromise*)fetchLatestRevisionsForArticleURL:(NSURL*)articleURL
                                     resultLimit:(NSUInteger)numberOfResults
                              endingWithRevision:(NSUInteger)revisionId;

@end
