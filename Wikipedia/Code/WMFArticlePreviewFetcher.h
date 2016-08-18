#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewFetcher : NSObject

- (AnyPromise *)fetchArticlePreviewResultsForArticleURLs:(NSArray<NSURL *> *)articleURLs
                                                 siteURL:(NSURL *)siteURL;

- (AnyPromise *)fetchArticlePreviewResultsForArticleURLs:(NSArray<NSURL *> *)articleURLs
                                                 siteURL:(NSURL *)siteURL
                                           extractLength:(NSUInteger)extractLength
                                          thumbnailWidth:(NSUInteger)thumbnailWidth;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
