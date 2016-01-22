
@import Foundation;

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFTrendingFetcher : NSObject

- (AnyPromise*)fetchTrendingForSite:(MWKSite*)site date:(NSDate*)date;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
