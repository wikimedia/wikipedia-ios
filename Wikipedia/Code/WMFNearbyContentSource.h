#import <WMF/WMFContentSource.h>
@import CoreLocation;
@class MWKDataStore;

extern const CLLocationDistance WMFNearbyForcedUpdateDistanceThresholdInMeters;

@interface WMFNearbyContentSource : NSObject <WMFContentSource, WMFAutoUpdatingContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL dataStore:(MWKDataStore *)dataStore;

- (instancetype)init NS_UNAVAILABLE;

@end
