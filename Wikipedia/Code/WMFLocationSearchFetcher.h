#import <Foundation/Foundation.h>
@import CoreLocation;
#import "Wikipedia-Swift.h"

@class WMFLocationSearchResults;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationSearchFetcher : NSObject

- (AnyPromise *)fetchArticlesWithSiteURL:(NSURL *)siteURL
                                location:(CLLocation *)location
                             resultLimit:(NSUInteger)resultLimit
                             cancellable:(inout id<Cancellable> __nullable *__nullable)outCancellable;


- (NSURLSessionDataTask* )fetchArticlesWithSiteURL:(NSURL *)siteURL
                                          location:(CLLocation *)location
                                       resultLimit:(NSUInteger)resultLimit
                                        completion:(void (^) (WMFLocationSearchResults* results))completion
                                           failure:(void(^)(NSError* error))failure;


- (BOOL)isFetching;

@end

NS_ASSUME_NONNULL_END
