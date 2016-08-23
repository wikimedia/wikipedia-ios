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
#import "WMFNearbyArticleCollectionViewCell.h"
#import "WMFEmptySectionCollectionViewCell.h"
#import "WMFNearbyPlaceholderCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UIViewController+WMFArticlePresentation.h"

#import "WMFLocationSearchListViewController.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFNearbySectionIdentifier = @"WMFNearbySectionIdentifier";
static NSUInteger const WMFNearbySectionFetchCount = 3;

@interface WMFNearbySectionController ()

@property (nonatomic, strong, readwrite) NSURL *searchSiteURL;
@property (nonatomic, strong, readwrite) CLLocation *location;
@property (nonatomic, strong, readwrite) CLPlacemark *placemark;

@property (nonatomic, strong) WMFLocationSearchFetcher *locationSearchFetcher;

@property (nonatomic, strong, nullable) WMFLocationSearchResults *searchResults;

@property (nonatomic, strong) WMFCompassViewModel *compassViewModel;

@end

@implementation WMFNearbySectionController

- (instancetype)initWithLocation:(CLLocation *)location
                       placemark:(nullable CLPlacemark *)placemark
                   searchSiteURL:(NSURL *)url
                       dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(url);
    NSParameterAssert(location);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.location = location;
        self.placemark = placemark;
        self.searchSiteURL = url;
        self.locationSearchFetcher = [[WMFLocationSearchFetcher alloc] init];
        self.compassViewModel = [[WMFCompassViewModel alloc] init];
    }
    return self;
}

#pragma mark - WMFExploreSectionController

- (id)sectionIdentifier {
    return WMFNearbySectionIdentifier;
}

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"nearby-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-nearby-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    if (self.placemark) {
        return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@, %@", self.placemark.name, self.placemark.locality] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
    } else if (self.searchResults.results.count > 0) {
        return [[NSAttributedString alloc] initWithString:[[self.searchResults.results firstObject] displayTitle] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
    } else {
        return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%f, %f", self.location.coordinate.latitude, self.location.coordinate.longitude] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
    }
}

- (NSString *)cellIdentifier {
    return [WMFNearbyArticleCollectionViewCell identifier];
}

- (UINib *)cellNib {
    return [WMFNearbyArticleCollectionViewCell wmf_classNib];
}

- (nullable NSString *)placeholderCellIdentifier {
    return [WMFNearbyPlaceholderCollectionViewCell identifier];
}

- (nullable UINib *)placeholderCellNib {
    return [WMFNearbyPlaceholderCollectionViewCell wmf_classNib];
}

- (void)configureCell:(WMFNearbyArticleCollectionViewCell *)cell withItem:(MWKLocationSearchResult *)item atIndexPath:(nonnull NSIndexPath *)indexPath {
    NSParameterAssert([item isKindOfClass:[MWKLocationSearchResult class]]);
    NSParameterAssert([cell isKindOfClass:[WMFNearbyArticleCollectionViewCell class]]);
    cell.titleText = item.displayTitle;
    cell.descriptionText = item.wikidataDescription;
    [cell setImageURL:item.thumbnailURL];
    [cell setDistanceProvider:[self.compassViewModel distanceProviderForResult:item]];
    [cell setBearingProvider:[self.compassViewModel bearingProviderForResult:item]];
}

- (void)configureEmptyCell:(WMFEmptySectionCollectionViewCell *)cell {
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
    return [WMFNearbyArticleCollectionViewCell estimatedRowHeight];
}

- (NSString *)analyticsContentType {
    return @"Nearby";
}

- (AnyPromise *)fetchData {
    if ([self fetchedResultsAreCloseToLocation:self.location]) {
        DDLogVerbose(@"Not fetching nearby titles for %@ since it is too close to previously fetched location: %@.",
                     self.location, self.searchResults.location);
        return [AnyPromise promiseWithValue:self.items];
    }

    return [self fetchTitlesForLocation:self.location];
}

- (UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = [self urlForItemAtIndexPath:indexPath];
    return [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
}

#pragma mark - WMFTitleProviding

- (nullable NSURL *)urlForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.searchResults urlForResultAtIndex:indexPath.row];
}

#pragma mark - WMFMoreFooterProviding

- (NSString *)footerText {
    return [MWLocalizedString(@"home-nearby-location-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.placemark.name];
}

- (UIViewController *)moreViewController {
    WMFLocationSearchListViewController *vc = [[WMFLocationSearchListViewController alloc] initWithLocation:self.location searchSiteURL:self.searchSiteURL dataStore:self.dataStore];
    return vc;
}

#pragma mark - Utility

- (BOOL)fetchedResultsAreCloseToLocation:(CLLocation *)location {
    if ([self.searchResults.location distanceFromLocation:location]<500 && [self.searchResults.searchSiteURL isEqual:self.searchSiteURL] && [self.searchResults.results count]> 0) {
        return YES;
    }

    return NO;
}

- (AnyPromise *)fetchTitlesForLocation:(CLLocation *__nullable)location {
    @weakify(self);
    return [self.locationSearchFetcher fetchArticlesWithSiteURL:self.searchSiteURL
                                                       location:location
                                                    resultLimit:WMFNearbySectionFetchCount
                                                    cancellable:NULL]
        .then(^(WMFLocationSearchResults *locationSearchResults) {
            @strongify(self);
            self.searchResults = locationSearchResults;
            return self.searchResults.results;
        })
        .catch(^(NSError *error) {
            //This means there were 0 results - not neccesarily a "real" error.
            //Only inform the delegate if we get a real error.
            if (!([error.domain isEqualToString:MTLJSONAdapterErrorDomain] && error.code == MTLJSONAdapterErrorInvalidJSONDictionary)) {
                return error;
            }
            return (NSError *)nil;
        });
}

@end

NS_ASSUME_NONNULL_END
