
#import <Foundation/Foundation.h>
@import CoreLocation;
#import "Wikipedia-Swift.h"

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationSearchFetcher : NSObject

- (AnyPromise*)fetchArticlesWithSite:(MWKSite*)site
                            location:(CLLocation*)location
                         resultLimit:(NSUInteger)resultLimit
                         cancellable:(inout id<Cancellable> __nullable* __nullable)outCancellable;

@end

NS_ASSUME_NONNULL_END
