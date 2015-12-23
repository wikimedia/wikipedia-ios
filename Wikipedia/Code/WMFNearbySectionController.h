
#import "WMFHomeSectionController.h"

@class WMFLocationManager, WMFNearbyViewModel, MWKSite, MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbySectionController : NSObject
    <WMFArticleHomeSectionController, WMFFetchingHomeSectionController>

- (instancetype)initWithSite:(MWKSite*)site
               savedPageList:(MWKSavedPageList*)savedPageList
             locationManager:(WMFLocationManager*)locationManager;

- (instancetype)initWithSite:(MWKSite*)site
               savedPageList:(MWKSavedPageList*)savedPageList
                   viewModel:(WMFNearbyViewModel*)viewModel NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) MWKSite* searchSite;

@end

NS_ASSUME_NONNULL_END