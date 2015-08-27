
#import "WMFHomeSectionController.h"

@class WMFLocationManager;
@class WMFLocationSearchFetcher;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbySectionController : NSObject <WMFHomeSectionController>

- (instancetype)initWithSite:(MWKSite*)site LocationManager:(WMFLocationManager*)locationManager locationSearchFetcher:(WMFLocationSearchFetcher*)locationSearchFetcher;

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong, readonly) WMFLocationManager* locationManager;
@property (nonatomic, strong, readonly) WMFLocationSearchFetcher* locationSearchFetcher;

@end

NS_ASSUME_NONNULL_END