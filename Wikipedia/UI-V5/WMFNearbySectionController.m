
#import "WMFNearbySectionController.h"

#import "WMFArticleListCollectionViewController.h"
#import "WMFNearbyTitleListDataSource.h"

#import "WMFLocationManager.h"
#import "WMFNearbyViewModel.h"

#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

//Promises
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

#import "WMFHomeNearbyCell.h"
#import "WMFNearbySectionEmptyCell.h"
#import "UIView+WMFDefaultNib.h"

#import <BlocksKit/BlocksKit+UIKit.h>

// TEMP
#import "SessionSingleton.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFNearbySectionIdentifier = @"WMFNearbySectionIdentifier";

@interface WMFNearbySectionController ()
<WMFNearbyViewModelDelegate>

@property (nonatomic, strong) WMFNearbyViewModel* viewModel;

@property (nonatomic, copy) NSString* emptySectionObject;

@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@end

@implementation WMFNearbySectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site locationManager:(WMFLocationManager*)locationManager {
    return [self initWithSite:site
                    viewModel:[[WMFNearbyViewModel alloc] initWithSite:site
                                                           resultLimit:3
                                                       locationManager:locationManager]];
}

- (instancetype)initWithSite:(MWKSite*)site viewModel:(WMFNearbyViewModel*)viewModel {
    NSParameterAssert(site);
    NSParameterAssert(viewModel);
    self = [super init];
    if (self) {
        self.viewModel          = viewModel;
        self.viewModel.delegate = self;
        self.emptySectionObject = @"EmptySection";
    }
    return self;
}

- (void)setSearchSite:(MWKSite* __nonnull)searchSite {
    self.viewModel.site = searchSite;
}

- (MWKSite*)searchSite {
    return self.viewModel.site;
}

- (id)sectionIdentifier {
    return WMFNearbySectionIdentifier;
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:@"Nearby your location" attributes:nil];
}

- (NSString*)footerText {
    return @"More from nearby your location";
}

- (NSArray*)items {
    if ([self.viewModel.locationSearchResults.results count] > 0) {
        return self.viewModel.locationSearchResults.results;
    } else {
        return @[self.emptySectionObject];
    }
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    id result = self.items[index];
    if ([result isKindOfClass:[MWKSearchResult class]]) {
        return [self.viewModel.locationSearchResults titleForResultAtIndex:index];
    }
    return nil;
}

- (void)registerCellsInCollectionView:(UICollectionView* __nonnull)collectionView {
    [collectionView registerNib:[WMFHomeNearbyCell wmf_classNib] forCellWithReuseIdentifier:[WMFHomeNearbyCell identifier]];
    [collectionView registerNib:[WMFNearbySectionEmptyCell wmf_classNib] forCellWithReuseIdentifier:[WMFNearbySectionEmptyCell identifier]];
}

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView
                                          atIndexPath:(NSIndexPath*)indexPath {
    if ([self.viewModel.locationSearchResults.results count] == 0) {
        return [WMFNearbySectionEmptyCell cellForCollectionView:collectionView indexPath:indexPath];
    } else {
        return [WMFHomeNearbyCell cellForCollectionView:collectionView indexPath:indexPath];
    }
}

- (void)configureCell:(UICollectionViewCell*)cell
           withObject:(id)object
     inCollectionView:(UICollectionView*)collectionView
          atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFHomeNearbyCell class]]) {
        WMFHomeNearbyCell* nearbyCell   = (id)cell;
        MWKLocationSearchResult* result = object;
        NSParameterAssert([result isKindOfClass:[MWKLocationSearchResult class]]);
        [nearbyCell setLocationSearchResult:result withTitle:[self titleForItemAtIndex:indexPath.item]];
        [self.viewModel autoUpdateResultAtIndex:indexPath.item];
        [nearbyCell setSavedPageList:self.savedPageList];
    } else {
        [self.viewModel startUpdates];
        WMFNearbySectionEmptyCell* nearbyCell = (id)cell;
        if (![nearbyCell.reloadButton bk_hasEventHandlersForControlEvents:UIControlEventTouchUpInside]) {
            @weakify(self);
            [nearbyCell.reloadButton bk_addEventHandler:^(id sender) {
                @strongify(self);
                [self.viewModel startUpdates];;
            } forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return self.viewModel.locationSearchResults.results.count > index;
}

- (UIViewController*)moreViewController {
    WMFNearbyTitleListDataSource* dataSource = [[WMFNearbyTitleListDataSource alloc] initWithSite:self.searchSite];
#warning Remove SessionSingleton
    WMFArticleListCollectionViewController* moreNearbyTitlesVC = [[WMFArticleListCollectionViewController alloc] init];
    moreNearbyTitlesVC.dataStore   = [[[SessionSingleton sharedInstance] userDataStore] dataStore];
    moreNearbyTitlesVC.recentPages = [[[SessionSingleton sharedInstance] userDataStore] historyList];
    moreNearbyTitlesVC.savedPages  = self.savedPageList;
    moreNearbyTitlesVC.dataSource  = dataSource;
    return moreNearbyTitlesVC;
}

#pragma mark - WMFNearbyViewModelDelegate

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error {
}

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didUpdateResults:(WMFLocationSearchResults*)results {
    [self.delegate controller:self didSetItems:results.results];
}

@end

NS_ASSUME_NONNULL_END
