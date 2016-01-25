
#import <SSDataSources/SSArrayDataSource.h>
#import "WMFTitleListDataSource.h"
@import CoreLocation;

@class WMFLocationManager, MWKSite, WMFSearchResultDistanceProvider, WMFSearchResultBearingProvider;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbyTitleListDataSource : SSArrayDataSource
    <WMFTitleListDataSource>

@property (nonatomic, strong, readonly) MWKSite* site;

@property (nonatomic, strong) CLLocation* location;

- (instancetype)initWithSite:(MWKSite*)site NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
