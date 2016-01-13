
#import "WMFHomeSectionController.h"

@class WMFLocationManager, WMFNearbyViewModel, MWKSite, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFNearbySectionIdentifier;

@interface WMFNearbySectionController : NSObject
    <WMFArticleHomeSectionController, WMFFetchingHomeSectionController>

- (instancetype)initWithSite:(MWKSite*)site
                   dataStore:(MWKDataStore*)dataStore
             locationManager:(WMFLocationManager*)locationManager;

- (instancetype)initWithSite:(MWKSite*)site
                   dataStore:(MWKDataStore*)dataStore
                   viewModel:(WMFNearbyViewModel*)viewModel NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) MWKSite* searchSite;

@end

NS_ASSUME_NONNULL_END