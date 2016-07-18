
#import <SSDataSources/SSArrayDataSource.h>
#import "WMFTitleListDataSource.h"
@import CoreLocation;

@class WMFLocationManager, WMFSearchResultDistanceProvider, WMFSearchResultBearingProvider;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbyTitleListDataSource : SSArrayDataSource
    <WMFTitleListDataSource>

@property (nonatomic, strong, readonly) NSURL* searchDomainURL;

@property (nonatomic, strong) CLLocation* location;

- (instancetype)initWithSearchDomainURL:(NSURL*)url NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
