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
#import "WMFEmptySectionTableViewCell.h"
#import "WMFNearbyPlaceholderTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"

#import "WMFLocationSearchListViewController.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFNearbySectionIdentifier         = @"WMFNearbySectionIdentifier";
static NSUInteger const WMFNearbySectionFetchCount = 3;

@interface WMFNearbySectionController ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong, readwrite) CLLocation* location;

@property (nonatomic, strong) WMFLocationSearchFetcher* locationSearchFetcher;

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong, nullable) WMFLocationSearchResults* searchResults;

@property (nonatomic, strong) WMFCompassViewModel* compassViewModel;

@end

@implementation WMFNearbySectionController

- (instancetype)initWithLocation:(CLLocation*)location
                            site:(MWKSite*)site
                       dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(site);
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.location              = location;
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

#pragma mark - WMFExploreSectionController

- (id)sectionIdentifier {
    return WMFNearbySectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"home-nearby"];
}

- (UIColor*)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor*)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString*)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-nearby-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString*)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%f, %f", self.location.coordinate.latitude, self.location.coordinate.longitude] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString*)cellIdentifier {
    return [WMFNearbyArticleTableViewCell identifier];
}

- (UINib*)cellNib {
    return [WMFNearbyArticleTableViewCell wmf_classNib];
}

- (nullable NSString*)placeholderCellIdentifier {
    return [WMFNearbyPlaceholderTableViewCell identifier];
}

- (nullable UINib*)placeholderCellNib {
    return [WMFNearbyPlaceholderTableViewCell wmf_classNib];
}

- (void)configureCell:(WMFNearbyArticleTableViewCell*)cell withItem:(MWKLocationSearchResult*)item atIndexPath:(nonnull NSIndexPath*)indexPath {
    NSParameterAssert([item isKindOfClass:[MWKLocationSearchResult class]]);
    NSParameterAssert([cell isKindOfClass:[WMFNearbyArticleTableViewCell class]]);

    cell.titleText       = item.displayTitle;
    cell.descriptionText = item.wikidataDescription;
    [cell setImageURL:item.thumbnailURL];
    [cell setDistanceProvider:[self.compassViewModel distanceProviderForResult:item]];
    [cell setBearingProvider:[self.compassViewModel bearingProviderForResult:item]];
    [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
}

- (void)configureEmptyCell:(WMFEmptySectionTableViewCell*)cell {
    cell.emptyTextLabel.text = MWLocalizedString(@"home-nearby-nothing", nil);
    [cell.reloadButton setTitle:MWLocalizedString(@"home-nearby-check-again", nil) forState:UIControlStateNormal];
}

- (void)willDisplaySection {
    [self.compassViewModel startUpdates];
}

- (void)didEndDisplayingSection {
    [self.compassViewModel stopUpdates];
}

- (CGFloat)estimatedRowHeight {
    return [WMFNearbyArticleTableViewCell estimatedRowHeight];
}

- (NSString*)analyticsName {
    return @"Nearby";
}

- (AnyPromise*)fetchData {
    if ([self fetchedResultsAreCloseToLocation:self.location]) {
        DDLogVerbose(@"Not fetching nearby titles for %@ since it is too close to previously fetched location: %@.",
                     self.location, self.searchResults.location);
        return [AnyPromise promiseWithValue:self.items];
    }

    return [self fetchTitlesForLocation:self.location];
}

#pragma mark - WMFTitleProviding

- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self.searchResults titleForResultAtIndex:indexPath.row];
}

#pragma mark - WMFMoreFooterProviding

- (NSString*)footerText {
    return MWLocalizedString(@"home-nearby-footer", nil);
}

- (UIViewController*)moreViewController {
    WMFLocationSearchListViewController* vc = [[WMFLocationSearchListViewController alloc] initWithLocation:self.location searchSite:self.searchSite dataStore:self.dataStore];
    return vc;
}

#pragma mark - Utility

- (BOOL)fetchedResultsAreCloseToLocation:(CLLocation*)location {
    if ([self.searchResults.location distanceFromLocation:location] < 500
        && [self.searchResults.searchSite isEqualToSite:self.searchSite] && [self.searchResults.results count] > 0) {
        return YES;
    }

    return NO;
}

- (AnyPromise*)fetchTitlesForLocation:(CLLocation* __nullable)location {
    @weakify(self);
    return [self.locationSearchFetcher fetchArticlesWithSite:self.searchSite
                                                    location:location
                                                 resultLimit:WMFNearbySectionFetchCount
                                                 cancellable:NULL]
           .then(^(WMFLocationSearchResults* locationSearchResults) {
        @strongify(self);
        self.searchResults = locationSearchResults;
        return self.searchResults.results;
    })
           .catch(^(NSError* error) {
        //This means there were 0 results - not neccesarily a "real" error.
        //Only inform the delegate if we get a real error.
        if (!([error.domain isEqualToString:MTLJSONAdapterErrorDomain] && error.code == MTLJSONAdapterErrorInvalidJSONDictionary)) {
            return error;
        }
        return (NSError*)nil;
    });
}

@end

NS_ASSUME_NONNULL_END
