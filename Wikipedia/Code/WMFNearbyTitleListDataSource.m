
#import "WMFNearbyTitleListDataSource.h"

// View Model
#import "WMFNearbyViewModel.h"

// Models
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKLocationSearchResult.h"
#import "MWKArticle.h"
#import "WMFLocationSearchResults.h"
#import "MWKHistoryEntry.h"

// Views

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbyTitleListDataSource ()
<WMFNearbyViewModelDelegate>

@property (nonatomic, strong) WMFNearbyViewModel* viewModel;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@end

@implementation WMFNearbyTitleListDataSource

- (instancetype)initWithSite:(MWKSite*)site {
    WMFNearbyViewModel* viewModel = [[WMFNearbyViewModel alloc] initWithSite:site
                                                                 resultLimit:20
                                                             locationManager:nil];
    return [self initWithSite:site viewModel:viewModel];
}

- (instancetype)initWithSite:(MWKSite*)site viewModel:(WMFNearbyViewModel*)viewModel {
    NSParameterAssert([viewModel.site isEqualToSite:site]);
    self = [super initWithItems:nil];
    if (self) {
        self.viewModel          = viewModel;
        self.viewModel.delegate = self;
    }
    return self;
}

- (void)setSite:(MWKSite* __nonnull)site {
    self.viewModel.site = site;
}

- (MWKSite*)site {
    return self.viewModel.site;
}

- (WMFSearchResultDistanceProvider*)distanceProviderForResultAtIndexPath:(NSIndexPath*)indexPath {
    return [self.viewModel distanceProviderForResultAtIndex:indexPath.row];
}

- (WMFSearchResultBearingProvider*)bearingProviderForResultAtIndexPath:(NSIndexPath*)indexPath {
    return [self.viewModel bearingProviderForResultAtIndex:indexPath.row];
}

#pragma mark - WMFArticleListDynamicDataSource

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath* __nonnull)indexPath {
    return NO;
}

- (NSArray*)titles {
    return [self.viewModel.locationSearchResults.results bk_map:^id (MWKLocationSearchResult* obj) {
        return [self.site titleWithString:obj.displayTitle];
    }];
}

- (NSUInteger)titleCount {
    return self.viewModel.locationSearchResults.results.count;
}

- (MWKLocationSearchResult*)searchResultForIndexPath:(NSIndexPath*)indexPath {
    MWKLocationSearchResult* result = self.viewModel.locationSearchResults.results[indexPath.row];
    return result;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKLocationSearchResult* result = [self searchResultForIndexPath:indexPath];
    return [self.site titleWithString:result.displayTitle];
}

- (void)startUpdating {
    [self.viewModel startUpdates];
}

- (void)stopUpdating {
    [self.viewModel stopUpdates];
}

#pragma mark - WMFNearbyViewModelDelegate

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error {
    // TODO: propagate error to view controller
}

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel
       didUpdateResults:(WMFLocationSearchResults*)locationSearchResults {
    // TEMP: remove this when artilce lists can handle article placeholders

    [self updateItems:locationSearchResults.results];
}

- (BOOL)nearbyViewModel:(WMFNearbyViewModel*)viewModel shouldFetchTitlesForLocation:(CLLocation*)location {
    return [self numberOfItems] == 0;
}

@end

NS_ASSUME_NONNULL_END
