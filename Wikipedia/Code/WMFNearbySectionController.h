
#import "WMFExploreSectionController.h"
@import CoreLocation;
@class WMFLocationManager, MWKSite, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFNearbySectionIdentifier;

@interface WMFNearbySectionController : NSObject
    <WMFArticleExploreSectionController, WMFFetchingExploreSectionController>

- (instancetype)initWithSite:(MWKSite*)site
                   dataStore:(MWKDataStore*)dataStore NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) MWKSite* searchSite;

@property (nonatomic, strong) CLLocation* location;

- (void)startMonitoringLocation;
- (void)stopMonitoringLocation;

@end

NS_ASSUME_NONNULL_END