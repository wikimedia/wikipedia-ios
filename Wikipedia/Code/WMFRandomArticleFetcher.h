
#import <Foundation/Foundation.h>

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher : NSObject

- (void)fetchRandomArticleWithSite:(MWKSite*)site failure:(WMFErrorHandler)failure success:(WMFSearchResultHandler)success;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END