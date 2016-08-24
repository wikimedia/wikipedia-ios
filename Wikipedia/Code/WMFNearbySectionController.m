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
#import "NSDate+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFNearbySectionIdentifier = @"WMFNearbySectionIdentifier";
static NSUInteger const WMFNearbySectionFetchCount = 3;

@interface WMFNearbySectionController ()<WMFLocationManagerDelegate>{
    PMKResolver currentLocationResolver;
}


@property (nonatomic, strong, readwrite) NSURL* searchSiteURL;
@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, strong, readwrite, nullable) CLLocation* currentLocation;
@property (nonatomic, strong, readwrite) CLPlacemark* placemark;

@property (nonatomic, strong) WMFLocationSearchFetcher *locationSearchFetcher;

@property (nonatomic, strong, nullable) WMFLocationSearchResults *searchResults;

@property (nonatomic, strong) WMFCompassViewModel *compassViewModel;

@property (nonatomic, strong, readwrite) NSDate* date;
@property (nonatomic, strong, readwrite) WMFLocationManager* currentLocationManager;

@end

@implementation WMFNearbySectionController


- (instancetype)initWithLocation:(CLLocation*)location
                       placemark:(nullable CLPlacemark*)placemark
                 searchSiteURL:(NSURL*)url
                            date:(nullable NSDate*)date
                       dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(url);
    NSParameterAssert(location);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.location              = location;
        self.currentLocation       = nil;
        self.placemark             = placemark;
        self.searchSiteURL         = url;
        self.date                  = date;
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

- (NSAttributedString*)headerSubTitle {
    if ([self.date isToday]){
        return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-nearby-sub-heading-your-location", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
    } else if (self.placemark) {
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
    [self.currentLocationManager stopMonitoringLocation];
    [self.compassViewModel stopUpdates];
}

- (CGFloat)estimatedRowHeight {
    return [WMFNearbyArticleCollectionViewCell estimatedRowHeight];
}

- (NSString *)analyticsContentType {
    return @"Nearby";
}

- (WMFLocationManager*)currentLocationManager {
    if (_currentLocationManager == nil) {
        _currentLocationManager          = [WMFLocationManager fineLocationManager];
        _currentLocationManager.delegate = self;
    }
    return _currentLocationManager;
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    self.currentLocation = location;
    currentLocationResolver(self.currentLocation);
    [self.currentLocationManager stopMonitoringLocation];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
}

- (AnyPromise*)fetchDataIfNeeded {
    if ([self.date isToday]){
        // The first nearby section should always show articles near the user's current location.
        return [super fetchDataUserInitiated];
    }else{
        return [super fetchDataIfNeeded];
    }
}

- (CLLocation *) location {
    if ([self.date isToday] && self.currentLocation != nil){
        return _currentLocation;
    }else{
        return _location;
    }
}

- (AnyPromise*)fetchData {
    AnyPromise *nearbyTitlesPromise = nil;
    if ([self fetchedResultsAreCloseToLocation:self.location]) {
        DDLogVerbose(@"Not fetching nearby titles for %@ since it is too close to previously fetched location: %@.",
                     self.location, self.searchResults.location);
        nearbyTitlesPromise = [AnyPromise promiseWithValue:self.items];
    }else{
        nearbyTitlesPromise = [self fetchTitlesForLocation:self.location];
    }

    if ([self.date isToday]){

        dispatchOnMainQueueAfterDelayInSeconds(0.1, ^{
            [self.currentLocationManager startMonitoringLocation];
        });
        
        return [[AnyPromise alloc] initWithResolver:&currentLocationResolver].then(^(PMKResolver resolve) {
            return nearbyTitlesPromise;
        }).catch(^(NSError* error){
            return nearbyTitlesPromise;
        });
    }else{
        return nearbyTitlesPromise;
    }
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

- (NSString*)footerText {
    if ([self.date isToday]){
        return MWLocalizedString(@"home-nearby-footer", nil);
    }else{
        return [MWLocalizedString(@"home-nearby-location-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.placemark.name];
    }
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
