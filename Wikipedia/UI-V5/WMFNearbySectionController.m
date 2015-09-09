
#import "WMFNearbySectionController.h"

#import "WMFArticleListCollectionViewController.h"
#import "WMFNearbyTitleListDataSource.h"

#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"

#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

//Promises
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

#import "WMFHomeNearbyCell.h"
#import "WMFNearbySectionEmptyCell.h"
#import "UIView+WMFDefaultNib.h"

#import <BlocksKit/BlocksKit+UIKit.h>

#import "CLLocation+WMFBearing.h"

// TEMP
#import "SessionSingleton.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFNearbySectionIdentifier  = @"WMFNearbySectionIdentifier";
static NSUInteger const WMFNearbySectionMaxResults = 3;

static CLLocationDistance WMFMinimumDistanceBeforeRefetching = 500.0; //meters before we update fetch

@interface WMFNearbySectionController ()<WMFNearbyControllerDelegate>

@property (nonatomic, strong, readwrite) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong, readwrite) WMFLocationManager* locationManager;

@property (nonatomic, strong, readwrite) WMFLocationSearchResults* nearbyResults;

@property (nonatomic, copy) NSString* emptySectionObject;

@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@end

@implementation WMFNearbySectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site
             locationManager:(WMFLocationManager*)locationManager
       locationSearchFetcher:(WMFLocationSearchFetcher*)locationSearchFetcher {
    NSParameterAssert(site);
    NSParameterAssert(locationManager);
    NSParameterAssert(locationSearchFetcher);

    self = [super init];
    if (self) {
        self.searchSite = site;

        self.locationSearchFetcher = locationSearchFetcher;

        locationManager.delegate = self;
        self.locationManager     = locationManager;

        self.emptySectionObject = @"EmptySection";
    }
    return self;
}

- (void)setSearchSite:(MWKSite* __nonnull)searchSite {
    _searchSite = searchSite;
    [self refetchNearbyArticlesIfSiteHasChanged];
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
    if ([self.nearbyResults.results count] > 0) {
        return self.nearbyResults.results;
    } else {
        return @[self.emptySectionObject];
    }
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    id result = self.items[index];
    if ([result isKindOfClass:[MWKSearchResult class]]) {
        MWKSite* site = self.nearbyResults.searchSite;
        return [site titleWithString:[(MWKSearchResult*)result displayTitle]];
    }
    return nil;
}

- (void)registerCellsInCollectionView:(UICollectionView* __nonnull)collectionView {
    [collectionView registerNib:[WMFHomeNearbyCell wmf_classNib] forCellWithReuseIdentifier:[WMFHomeNearbyCell identifier]];
    [collectionView registerNib:[WMFNearbySectionEmptyCell wmf_classNib] forCellWithReuseIdentifier:[WMFNearbySectionEmptyCell identifier]];
}

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath {
    if ([self.nearbyResults.results count] == 0) {
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
        [nearbyCell setSavedPageList:self.savedPageList];
        nearbyCell.descriptionText = result.wikidataDescription;
        nearbyCell.title           = [self titleForItemAtIndex:indexPath.item];
        nearbyCell.distance        = result.distanceFromQueryCoordinates;
        nearbyCell.imageURL        = result.thumbnailURL;
    } else {
        [self.locationManager startMonitoringLocation];
        WMFNearbySectionEmptyCell* nearbyCell = (id)cell;
        if (![nearbyCell.reloadButton bk_hasEventHandlersForControlEvents:UIControlEventTouchUpInside]) {
            @weakify(self);
            [nearbyCell.reloadButton bk_addEventHandler:^(id sender) {
                @strongify(self);
                [self.locationManager restartLocationMonitoring];
            } forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return self.nearbyResults.results.count > index;
}

- (UIViewController*)moreViewController {
    NSAssert(self.nearbyResults.results.count > 0 && [[self.locationManager class] isAuthorized],
             @"Shouldn't be able to present more nearby titles if we're not able to determine location."
             " Current status is %d", [CLLocationManager authorizationStatus]);
    #warning Remove SessionSingleton
    WMFNearbyTitleListDataSource* dataSource                   = [[WMFNearbyTitleListDataSource alloc] initWithSite:self.searchSite];
    WMFArticleListCollectionViewController* moreNearbyTitlesVC = [[WMFArticleListCollectionViewController alloc] init];
    moreNearbyTitlesVC.dataStore   = [[[SessionSingleton sharedInstance] userDataStore] dataStore];
    moreNearbyTitlesVC.recentPages = [[[SessionSingleton sharedInstance] userDataStore] historyList];
    moreNearbyTitlesVC.savedPages  = self.savedPageList;
    moreNearbyTitlesVC.dataSource  = dataSource;
    return moreNearbyTitlesVC;
}

#pragma mark - Section Updates

- (void)updateSectionWithResults:(WMFLocationSearchResults*)results {
    [self.delegate controller:self didSetItems:results.results];
}

- (void)updateSectionWithLocation:(CLLocation*)location {
    [self.delegate controller:self enumerateVisibleCells:^(WMFHomeNearbyCell* cell, NSIndexPath* indexPath){
        if ([cell isKindOfClass:[WMFHomeNearbyCell class]]) {
            MWKLocationSearchResult* result = [self items][indexPath.item];
            cell.distance = [location distanceFromLocation:result.location];
        }
    }];
}

- (void)updateSectionWithHeading:(CLHeading*)heading {
    [self.delegate controller:self enumerateVisibleCells:^(WMFHomeNearbyCell* cell, NSIndexPath* indexPath){
        if ([cell isKindOfClass:[WMFHomeNearbyCell class]]) {
            MWKLocationSearchResult* result = [self items][indexPath.item];
            cell.headingAngle = [self headingAngleToLocation:result.location
                                               startLocation:self.locationManager.lastLocation
                                                     heading:heading
                                        interfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        }
    }];
}

- (void)updateSectionWithLocationError:(NSError*)error {
}

- (void)updateSectionWithSearchError:(NSError*)error {
}

#pragma mark - WMFNearbyControllerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    [self updateSectionWithLocation:location];
    [self fetchNearbyArticlesIfLocationHasSignificantlyChanged:location];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
    [self updateSectionWithHeading:heading];
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
    [self updateSectionWithLocationError:error];
}

#pragma mark - Fetch

- (void)refetchNearbyArticlesIfSiteHasChanged {
    if (self.locationManager.lastLocation && ![self.nearbyResults.searchSite isEqualToSite:self.searchSite]) {
        [self fetchNearbyArticlesWithLocation:self.locationManager.lastLocation];
    }
}

- (void)fetchNearbyArticlesIfLocationHasSignificantlyChanged:(CLLocation*)location {
    if (self.nearbyResults.location
        && [self.nearbyResults.location distanceFromLocation:location] < WMFMinimumDistanceBeforeRefetching) {
        return;
    }

    [self fetchNearbyArticlesWithLocation:location];
}

- (void)fetchNearbyArticlesWithLocation:(CLLocation*)location {
    if (!location) {
        return;
    }

    if (self.locationSearchFetcher.isFetching) {
        return;
    }

    @weakify(self);
    [self.locationSearchFetcher fetchArticlesWithSite:self.searchSite
                                             location:location
                                          resultLimit:WMFNearbySectionMaxResults]
    .then(^(WMFLocationSearchResults* results){
        @strongify(self);
        self.nearbyResults = results;
        [self updateSectionWithResults:results];
    })
    .catch(^(NSError* error){
        @strongify(self);
        [self updateSectionWithSearchError:error];
    });
}

#pragma mark - Compass Heading

- (NSNumber*)headingAngleToLocation:(CLLocation*)toLocation
                      startLocation:(CLLocation*)startLocation
                            heading:(CLHeading*)heading
               interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Get angle between device and article coordinates.
    double angleDegrees = [startLocation wmf_bearingToLocation:toLocation forCurrentHeading:heading];

    if (angleDegrees > 360.0) {
        angleDegrees -= 360.0;
    } else if (angleDegrees < 0.0) {
        angleDegrees += 360.0;
    }

    // Adjust for interface orientation.
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            angleDegrees += 90.0;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angleDegrees -= 90.0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angleDegrees += 180.0;
            break;
        default: //UIInterfaceOrientationPortrait
            break;
    }

    return @(DEGREES_TO_RADIANS(angleDegrees));
}

@end

NS_ASSUME_NONNULL_END
