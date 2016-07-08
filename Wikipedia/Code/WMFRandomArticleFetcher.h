
#import <Foundation/Foundation.h>

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher : NSObject

- (void)fetchRandomArticleWithSite:(MWKSite*)site failure:(nonnull WMFErrorHandler)failure success:(nonnull WMFSearchResultHandler)success;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END