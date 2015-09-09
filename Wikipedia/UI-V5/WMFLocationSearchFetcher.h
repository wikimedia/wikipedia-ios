
#import <Foundation/Foundation.h>
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationSearchFetcher : NSObject

- (AnyPromise*)fetchArticlesWithSite:(MWKSite*)site
                            location:(CLLocation*)location
                         resultLimit:(NSUInteger)resultLimit;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
