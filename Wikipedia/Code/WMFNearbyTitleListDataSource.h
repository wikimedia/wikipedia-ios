
#import <SSDataSources/SSArrayDataSource.h>
#import "WMFTitleListDataSource.h"

@class WMFNearbyViewModel, WMFLocationManager, MWKSite, WMFSearchResultDistanceProvider, WMFSearchResultBearingProvider;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbyTitleListDataSource : SSArrayDataSource
    <WMFArticleListDynamicDataSource>

@property (nonatomic, strong) MWKSite* site;

- (instancetype)initWithSite:(MWKSite*)site;

- (instancetype)initWithSite:(MWKSite*)site
                   viewModel:(WMFNearbyViewModel*)viewModel NS_DESIGNATED_INITIALIZER;

- (WMFSearchResultDistanceProvider*)distanceProviderForResultAtIndexPath:(NSIndexPath*)indexPath;
- (WMFSearchResultBearingProvider*)bearingProviderForResultAtIndexPath:(NSIndexPath*)indexPath;

@end

NS_ASSUME_NONNULL_END
