
#import "WMFNearbySectionController.h"

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

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFNearbySectionIdentifier  = @"WMFNearbySectionIdentifier";
static NSUInteger const WMFNearbySectionMaxResults = 3;

static CLLocationDistance WMFMinimumDistanceBeforeRefetching = 500.0; //meters before we update fetch

@interface WMFNearbySectionController ()<WMFNearbyControllerDelegate>

@property (nonatomic, strong, readwrite) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong, readwrite) WMFLocationManager* locationManager;

@property (nonatomic, strong, readwrite) WMFLocationSearchResults* nearbyResults;

@property (nonatomic, copy) NSString* emptySectionObject;

@end

@implementation WMFNearbySectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site LocationManager:(WMFLocationManager*)locationManager locationSearchFetcher:(WMFLocationSearchFetcher*)locationSearchFetcher {
    NSParameterAssert(site);
    NSParameterAssert(locationManager);
    NSParameterAssert(locationSearchFetcher);

    self = [super init];
    if (self) {
        self.searchSite = site;

        locationSearchFetcher.maximumNumberOfResults = WMFNearbySectionMaxResults;
        self.locationSearchFetcher                   = locationSearchFetcher;

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
    MWKSearchResult* result = self.items[index];
    MWKSite* site           = self.nearbyResults.searchSite;
    MWKTitle* title         = [site titleWithString:result.displayTitle];
    return title;
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

- (void)configureCell:(UICollectionViewCell*)cell withObject:(id)object inCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFHomeNearbyCell class]]) {
        WMFHomeNearbyCell* nearbyCell   = (id)cell;
        MWKLocationSearchResult* result = object;
        nearbyCell.titleText       = result.displayTitle;
        nearbyCell.descriptionText = result.wikidataDescription;
        nearbyCell.distance        = result.distanceFromQueryCoordinates;
        nearbyCell.imageURL        = result.thumbnailURL;
    } else {
        WMFNearbySectionEmptyCell* nearbyCell = (id)cell;
        if (![nearbyCell.reloadButton bk_hasEventHandlersForControlEvents:UIControlEventTouchUpInside]) {
            [nearbyCell.reloadButton bk_addEventHandler:^(id sender) {
                [self.locationManager stopMonitoringLocation];
                [self.locationManager startMonitoringLocation];
            } forControlEvents:UIControlEventTouchUpInside];
        }
    }
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
            cell.headingAngle = [self headingAngleToLocation:result.location startLocationLocation:self.locationManager.lastLocation heading:heading interfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
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

- (void)nearbyController:(WMFLocationManager*)controller didfetchNearbyResults:(WMFLocationSearchResults*)results {
    [self updateSectionWithResults:results];
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
    [self updateSectionWithLocationError:error];
}

#pragma mark - Fetch

- (void)refetchNearbyArticlesIfSiteHasChanged {
    if (!self.nearbyResults) {
        return;
    }
    if ([self.nearbyResults.searchSite isEqualToSite:self.searchSite]) {
        return;
    }

    [self fetchNearbyArticlesWithLocation:self.locationManager.lastLocation];
}

- (void)fetchNearbyArticlesIfLocationHasSignificantlyChanged:(CLLocation*)location {
    if (self.nearbyResults.location && [self.nearbyResults.location distanceFromLocation:location] < WMFMinimumDistanceBeforeRefetching) {
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

    [self.locationSearchFetcher fetchArticlesWithSite:self.searchSite location:location]
    .then(^(WMFLocationSearchResults* results){
        self.nearbyResults = results;
        [self updateSectionWithResults:results];
    })
    .catch(^(NSError* error){
        [self updateSectionWithSearchError:error];
    });
}

- (void)reloadNearby {
    [self.locationManager stopMonitoringLocation];
    [self.locationManager startMonitoringLocation];
}

#pragma mark - Compass Heading

- (NSNumber*)headingAngleToLocation:(CLLocation*)toLocation startLocationLocation:(CLLocation*)startLocation heading:(CLHeading*)heading interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Get angle between device and article coordinates.
    double angleRadians = [self headingBetweenLocation:startLocation.coordinate andLocation:toLocation.coordinate];

    // Adjust for device rotation (deviceHeading is in degrees).
    double angleDegrees = RADIANS_TO_DEGREES(angleRadians);
    angleDegrees -= heading.trueHeading;

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

- (double)headingBetweenLocation:(CLLocationCoordinate2D)loc1
                     andLocation:(CLLocationCoordinate2D)loc2 {
    // From: http://www.movable-type.co.uk/scripts/latlong.html
    double dy = loc2.longitude - loc1.longitude;
    double y  = sin(dy) * cos(loc2.latitude);
    double x  = cos(loc1.latitude) * sin(loc2.latitude) - sin(loc1.latitude) * cos(loc2.latitude) * cos(dy);
    return atan2(y, x);
}

@end

NS_ASSUME_NONNULL_END
