#import "WMFNearbySectionController.h"

// Controllers
#import "WMFNearbyTitleListDataSource.h"
#import "WMFLocationManager.h"
#import "WMFCompassViewModel.h"
#import "WMFLocationSearchFetcher.h"

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

#import "WMFLocationSearchListViewController.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFNearbySectionIdentifier         = @"WMFNearbySectionIdentifier";
static NSUInteger const WMFNearbySectionFetchCount = 3;

@interface WMFNearbySectionController ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;

@property (nonatomic, strong) WMFLocationSearchFetcher* locationSearchFetcher;

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong, nullable) WMFLocationSearchResults* searchResults;

@property (nonatomic, strong) WMFCompassViewModel* compassViewModel;

@property (nonatomic, weak) id<Cancellable> lastFetch;
@property (nonatomic, strong, nullable) NSError* nearbyError;

@end

@implementation WMFNearbySectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site
                   dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(site);
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.searchSite            = site;
        self.dataStore             = dataStore;
        self.locationSearchFetcher = [[WMFLocationSearchFetcher alloc] init];
        self.compassViewModel      = [[WMFCompassViewModel alloc] init];
    }
    return self;
}

#pragma mark - Accessors

- (MWKSavedPageList*)savedPageList {
    return self.dataStore.userDataStore.savedPageList;
}

- (void)setLocation:(CLLocation*)location {
    if (WMF_IS_EQUAL(_location, location)) {
        return;
    }
    _location = location;
}

- (BOOL)hasResults {
    return self.searchResults && self.searchResults.results && self.searchResults.results.count > 0;
}

- (void)setSearchResults:(nullable WMFLocationSearchResults*)searchResults {
    _searchResults = searchResults;
    if (!_searchResults) {
        self.nearbyError = nil;
    }
}

- (void)setNearbyError:(nullable NSError*)nearbyError {
    _nearbyError = nearbyError;
    if (_nearbyError) {
        self.searchResults = nil;
    }
}

#pragma mark - WMFExploreSectionController

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
    if ([self hasResults]) {
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
    if ([self hasResults]) {
        return [WMFNearbyArticleTableViewCell cellForTableView:tableView];
    } else if (self.nearbyError) {
        return [WMFEmptyNearbyTableViewCell cellForTableView:tableView];
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
        [nearbyCell setDistanceProvider:[self.compassViewModel distanceProviderForResult:result]];
        [nearbyCell setBearingProvider:[self.compassViewModel bearingProviderForResult:result]];
        [nearbyCell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
    } else if ([cell isKindOfClass:[WMFEmptyNearbyTableViewCell class]]) {
        WMFEmptyNearbyTableViewCell* nearbyCell = (id)cell;
        if (![nearbyCell.reloadButton bk_hasEventHandlersForControlEvents:UIControlEventTouchUpInside]) {
            @weakify(self);
            [nearbyCell.reloadButton bk_addEventHandler:^(id sender) {
                @strongify(self);
                self.nearbyError = nil;
                [self.delegate controller:self didSetItems:self.items];
                [self fetchTitlesForLocation:self.location];
            } forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return [self hasResults];
}

- (UIViewController*)moreViewController {
    WMFLocationSearchListViewController* vc = [[WMFLocationSearchListViewController alloc] initWithLocation:self.location searchSite:self.searchSite dataStore:self.dataStore];
    return vc;
}

#pragma mark - Fetch

- (BOOL)fetchedResultsAreCloseToLocation:(CLLocation*)location {
    if ([self.searchResults.location distanceFromLocation:location] < 500
        && [self.searchResults.searchSite isEqualToSite:self.searchSite] && [self.searchResults.results count] > 0) {
        return YES;
    }

    return NO;
}

- (void)fetchDataIfNeeded {
    if (!self.location) {
        return;
    }

    if ([self fetchedResultsAreCloseToLocation:self.location]) {
        DDLogVerbose(@"Not fetching nearby titles for %@ since it is too close to previously fetched location: %@.",
                     self.location, self.searchResults.location);
        return;
    }

    [self fetchTitlesForLocation:self.location];
}

- (void)fetchTitlesForLocation:(CLLocation* __nullable)location {
    [self.lastFetch cancel];
    id<Cancellable> fetch;
    @weakify(self);
    [self.locationSearchFetcher fetchArticlesWithSite:self.searchSite
                                             location:location
                                          resultLimit:WMFNearbySectionFetchCount
                                          cancellable:&fetch]
    .then(^(WMFLocationSearchResults* locationSearchResults) {
        @strongify(self);
        self.searchResults = locationSearchResults;
        [self.delegate controller:self didSetItems:self.items];
    })
    .catch(^(NSError* error) {
        @strongify(self);
        //This means there were 0 results - not neccesarily a "real" error.
        //Only inform the delegate if we get a real error.
        if (!([error.domain isEqualToString:MTLJSONAdapterErrorDomain] && error.code == MTLJSONAdapterErrorInvalidJSONDictionary)) {
            [self.delegate controller:self didFailToUpdateWithError:error];
        }
    });
    self.lastFetch = fetch;
}

#pragma mark - Location Updates

- (void)startMonitoringLocation {
    [self.compassViewModel startUpdates];
}

- (void)stopMonitoringLocation {
    [self.compassViewModel stopUpdates];
}

- (NSString*)analyticsName {
    return @"Nearby";
}

- (CGFloat)estimatedRowHeight {
    return [WMFNearbyArticleTableViewCell estimatedRowHeight];
}

@end

NS_ASSUME_NONNULL_END
