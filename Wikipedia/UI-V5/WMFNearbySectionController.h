
#import "WMFHomeSectionController.h"

@class WMFLocationManager;
@class WMFLocationSearchFetcher;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbySectionController : NSObject <WMFHomeSectionController>

- (instancetype)initWithLocationManager:(WMFLocationManager*)locationManager locationSearchFetcher:(WMFLocationSearchFetcher*)locationSearchFetcher;

@property (nonatomic, strong, readonly) WMFLocationManager* locationManager;
@property (nonatomic, strong, readonly) WMFLocationSearchFetcher* locationSearchFetcher;

@end

NS_ASSUME_NONNULL_END