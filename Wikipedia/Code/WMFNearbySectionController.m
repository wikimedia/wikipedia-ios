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
#import "WMFNearbyPlaceholderTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFNearbySectionIdentifier = @"WMFNearbySectionIdentifier";

@interface WMFNearbySectionController ()
<WMFNearbyViewModelDelegate>

@property (nonatomic, strong) WMFNearbyViewModel* viewModel;

@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) WMFLocationSearchResults* searchResults;

@property (nonatomic, strong, nullable) NSError* nearbyError;

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
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"main-menu-nearby", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_homeSectionHeaderTextColor]}];
}

- (NSString*)footerText {
    return MWLocalizedString(@"home-nearby-footer", nil);
}

- (NSArray*)items {
    if ([self.searchResults.results count] > 0) {
        return self.searchResults.results;
    } else if (self.nearbyError) {
        return @[@1];
    } else {
        return @[@1, @2, @3];
    }
}

- (nullable MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    id result = self.items[index];
    if ([result isKindOfClass:[MWKSearchResult class]]) {
        return [self.searchResults titleForResultAtIndex:index];
    }
    return nil;
}

- (void)registerCellsInTableView:(UITableView* __nonnull)tableView {
    [tableView registerNib:[WMFNearbyArticleTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFNearbyArticleTableViewCell identifier]];
    [tableView registerNib:[WMFNearbyPlaceholderTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFNearbyPlaceholderTableViewCell identifier]];
    [tableView registerNib:[WMFEmptyNearbyTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFEmptyNearbyTableViewCell identifier]];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if (self.nearbyError) {
        return [WMFEmptyNearbyTableViewCell cellForTableView:tableView];
    } else if ([self hasResults]) {
        return [WMFNearbyArticleTableViewCell cellForTableView:tableView];
    } else {
        return [WMFNearbyPlaceholderTableViewCell cellForTableView:tableView];
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
        [nearbyCell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
    } else if ([cell isKindOfClass:[WMFEmptyNearbyTableViewCell class]]) {
        WMFEmptyNearbyTableViewCell* nearbyCell = (id)cell;
        if (![nearbyCell.reloadButton bk_hasEventHandlersForControlEvents:UIControlEventTouchUpInside]) {
            @weakify(self);
            [nearbyCell.reloadButton bk_addEventHandler:^(id sender) {
                @strongify(self);
                self.nearbyError = nil;
                [self.delegate controller:self didSetItems:self.items];
                [self.viewModel stopUpdates];
                [self.viewModel startUpdates];
            } forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return [self hasResults];
}

- (SSArrayDataSource<WMFTitleListDataSource>*)extendedListDataSource {
    return [[WMFNearbyTitleListDataSource alloc] initWithSite:self.searchSite];
}

- (BOOL)hasResults {
    return self.searchResults && self.searchResults.results && self.searchResults.results.count > 0;
}

- (void)fetchDataIfNeeded {
    // Start updates if they haven't been started already. Don't redundantly start (or restart) or else views will flicker.
    [self.viewModel startUpdates];
}

#pragma mark - WMFNearbyViewModelDelegate

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error {
    if (!([error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorLocationUnknown)
        || !self.searchResults) {
        // only show error view if empty or error is not "unknown location"
        self.nearbyError = error;
        [self.delegate controller:self didSetItems:self.items];
    }

    //This means there were 0 results - not neccesarily a "real" error.
    //Only inform the delegate if we get a real error.
    if (!([error.domain isEqualToString:MTLJSONAdapterErrorDomain] && error.code == MTLJSONAdapterErrorInvalidJSONDictionary)) {
        [self.delegate controller:self didFailToUpdateWithError:error];
    }

    //Don't try to update after we get an error.
    [self.viewModel stopUpdates];
}

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didUpdateResults:(WMFLocationSearchResults*)results {
    self.nearbyError   = nil;
    self.searchResults = results;
    [self.delegate controller:self didSetItems:self.items];
}

- (NSString*)analyticsName {
    return @"Nearby";
}

@end

NS_ASSUME_NONNULL_END
