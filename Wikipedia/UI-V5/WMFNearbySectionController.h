
#import "WMFHomeSectionController.h"

@class WMFLocationManager, WMFNearbyViewModel, MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbySectionController : NSObject <WMFHomeSectionController>

- (instancetype)initWithSite:(MWKSite*)site
             locationManager:(WMFLocationManager*)locationManager;

- (instancetype)initWithSite:(MWKSite*)site viewModel:(WMFNearbyViewModel*)viewModel NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) MWKSite* searchSite;

@end

NS_ASSUME_NONNULL_END