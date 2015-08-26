
#import <Foundation/Foundation.h>
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationSearchFetcher : NSObject

@property (nonatomic, assign) NSUInteger maximumNumberOfResults;

- (AnyPromise*)fetchArticlesWithSite:(MWKSite*)site location:(CLLocation*)location;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
