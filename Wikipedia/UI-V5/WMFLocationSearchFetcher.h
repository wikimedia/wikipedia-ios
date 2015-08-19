
#import <Foundation/Foundation.h>
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationSearchFetcher : NSObject

- (instancetype)initWithSearchSite:(MWKSite*)site;

@property (nonatomic, strong, readonly) MWKSite* searchSite;

@property (nonatomic, assign) NSUInteger maximumNumberOfResults;

- (AnyPromise*)fetchArticlesWithLocation:(CLLocation*)location;

@end

NS_ASSUME_NONNULL_END
