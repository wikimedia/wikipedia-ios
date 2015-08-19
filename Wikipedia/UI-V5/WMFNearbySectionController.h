
#import "WMFHomeSectionController.h"

@class WMFLocationManager;
@class WMFLocationSearchFetcher;
@class SSSectionedDataSource;

@interface WMFNearbySectionController : WMFHomeSectionController

- (instancetype)initWithDataSource:(SSSectionedDataSource*)dataSource locationManager:(WMFLocationManager*)locationManager locationSearchFetcher:(WMFLocationSearchFetcher*)locationSearchFetcher;

@property (nonatomic, strong, readonly) WMFLocationManager* locationManager;
@property (nonatomic, strong, readonly) WMFLocationSearchFetcher* locationSearchFetcher;

@end
