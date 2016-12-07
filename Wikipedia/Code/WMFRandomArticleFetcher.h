#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher : NSObject

- (void)fetchRandomArticleWithSiteURL:(NSURL *)siteURL failure:(nonnull WMFErrorHandler)failure success:(nonnull WMFMWKSearchResultHandler)success;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
