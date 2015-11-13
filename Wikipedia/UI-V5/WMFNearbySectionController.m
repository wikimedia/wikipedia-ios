#import "WMFNearbySectionController.h"

// Controllers
#import "WMFNearbyTitleListDataSource.h"
#import "WMFNearbyViewModel.h"
#import "WMFLocationManager.h"

// Models
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"
#import "WMFLocationSearchResults.h"
#import "WMFSearchResultBearingProvider.h"
#import "WMFSearchResultDistanceProvider.h"

// Frameworks
#import "Wikipedia-Swift.h"
#import <BlocksKit/BlocksKit+UIKit.h>

// Views
#import "WMFNearbyArticleTableViewCell.h"
#import "WMFEmptyNearbyTableViewCell.h"
#import "UIView+WMFDefaultNib.h"

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

- (instancetype)initWithSite:(MWKSite*)site
               savedPageList:(MWKSavedPageList*)savedPageList
             locationManager:(WMFLocationManager*)locationManager {
    return [self initWithSite:site
                savedPageList:savedPageList
                    viewModel:[[WMFNearbyViewModel alloc] initWithSite:site
                                                           resultLimit:3
                                                       locationManager:locationManager]];
}

- (instancetype)initWithSite:(MWKSite*)site
               savedPageList:(MWKSavedPageList*)savedPageList
                   viewModel:(WMFNearbyViewModel*)viewModel {
    NSParameterAssert(site);
    NSParameterAssert(savedPageList);
    NSParameterAssert(viewModel);
    self = [super init];
    if (self) {
        self.savedPageList      = savedPageList;
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

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"home-nearby"];
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"main-menu-nearby", nil) attributes:nil];
}

- (NSString*)footerText {
    return MWLocalizedString(@"home-nearby-footer", nil);
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

- (void)registerCellsInTableView:(UITableView* __nonnull)tableView {
    [tableView registerNib:[WMFNearbyArticleTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFNearbyArticleTableViewCell identifier]];
    [tableView registerNib:[WMFEmptyNearbyTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFEmptyNearbyTableViewCell identifier]];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([self.viewModel.locationSearchResults.results count] == 0) {
        return [WMFEmptyNearbyTableViewCell cellForTableView:tableView];
    } else {
        return [WMFNearbyArticleTableViewCell cellForTableView:tableView];
    }
}

- (void)configureCell:(UITableViewCell*)cell withObject:(id)object inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFNearbyArticleTableViewCell class]] && [object isKindOfClass:[MWKLocationSearchResult class]]) {
        WMFNearbyArticleTableViewCell* nearbyCell = (id)cell;
        MWKLocationSearchResult* result           = object;
        NSParameterAssert([result isKindOfClass:[MWKLocationSearchResult class]]);
        nearbyCell.titleText       = result.displayTitle;
        nearbyCell.descriptionText = result.wikidataDescription;
        [nearbyCell setImageURL:result.thumbnailURL];
        [nearbyCell setDistanceProvider:[self.viewModel distanceProviderForResultAtIndex:indexPath.item]];
        [nearbyCell setBearingProvider:[self.viewModel bearingProviderForResultAtIndex:indexPath.item]];
    } else if ([cell isKindOfClass:[WMFEmptyNearbyTableViewCell class]] && (object == self.emptySectionObject)) {
        WMFEmptyNearbyTableViewCell* nearbyCell = (id)cell;
        if (![nearbyCell.reloadButton bk_hasEventHandlersForControlEvents:UIControlEventTouchUpInside]) {
            @weakify(self);
            [nearbyCell.reloadButton bk_addEventHandler:^(id sender) {
                @strongify(self);
                [self.viewModel startUpdates];
            } forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return self.viewModel.locationSearchResults.results.count > index;
}

- (SSArrayDataSource<WMFTitleListDataSource>*)extendedListDataSource {
    return [[WMFNearbyTitleListDataSource alloc] initWithSite:self.searchSite];
}

#pragma mark - WMFNearbyViewModelDelegate

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error {
}

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didUpdateResults:(WMFLocationSearchResults*)results {
    [self.delegate controller:self didSetItems:results.results];
}

@end

NS_ASSUME_NONNULL_END
