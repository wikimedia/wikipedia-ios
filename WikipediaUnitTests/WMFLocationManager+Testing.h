#import <WMF/WMF.h>
#import <WMF/WMFLocationManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager (Testing)

- (instancetype)initWithLocationManager:(CLLocationManager *)locationManager device:(UIDevice *)device;

@end

NS_ASSUME_NONNULL_END
