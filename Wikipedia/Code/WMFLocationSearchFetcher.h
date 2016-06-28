
#import <Foundation/Foundation.h>
@import CoreLocation;
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationSearchFetcher : NSObject

- (AnyPromise*)fetchArticlesWithDomainURL:(NSURL*)domainURL
                                 location:(CLLocation*)location
                              resultLimit:(NSUInteger)resultLimit
                              cancellable:(inout id<Cancellable> __nullable* __nullable)outCancellable;

@end

NS_ASSUME_NONNULL_END
