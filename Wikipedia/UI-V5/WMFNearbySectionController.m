
#import "WMFNearbySectionController.h"

#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"
#import "SSSectionedDataSource+WMFSectionConvenience.h"

#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

//Promises
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

#import "WMFHomeNearbyCell.h"
#import "UIView+WMFDefaultNib.h"

static NSString* const WMFNearbySectionIdentifier = @"WMFNearbySectionIdentifier";
static NSUInteger const WMFNearbySectionMaxResults = 3;

static CLLocationDistance WMFMinimumDistanceBeforeRefetching = 500.0; //meters before we update fetch

@interface WMFNearbySectionController ()<WMFNearbyControllerDelegate>

@property (nonatomic, strong, readwrite) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong, readwrite) WMFLocationManager* locationManager;

@property (nonatomic, strong, readwrite) WMFLocationSearchResults* nearbyResults;

@end

@implementation WMFNearbySectionController

- (instancetype)initWithDataSource:(SSSectionedDataSource*)dataSource locationManager:(WMFLocationManager*)locationManager locationSearchFetcher:(WMFLocationSearchFetcher*)locationSearchFetcher
{
    NSParameterAssert(locationManager);
    NSParameterAssert(locationSearchFetcher);
    
    self = [super initWithDataSource:dataSource];
    if (self) {
        
        locationSearchFetcher.maximumNumberOfResults = WMFNearbySectionMaxResults;
        self.locationSearchFetcher = locationSearchFetcher;
        
        locationManager.delegate = self;
        self.locationManager = locationManager;
        
        
    }
    return self;
}

- (id)sectionIdentifier{
    return WMFNearbySectionIdentifier;
}

- (NSString*)headerText{
    return  @"Nearby";
}

- (NSString*)footerText{
    return @"More Nearby";
}

- (void)registerCellsInCollectionView:(UICollectionView * __nonnull)collectionView{
    [collectionView registerNib:[WMFHomeNearbyCell wmf_classNib] forCellWithReuseIdentifier:[WMFHomeNearbyCell identifier]];
}

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath{
    return [WMFHomeNearbyCell cellForCollectionView:collectionView indexPath:indexPath];
}

- (void)configureCell:(UICollectionViewCell*)cell withObject:(id)object atIndexPath:(NSIndexPath*)indexPath{
    
    WMFHomeNearbyCell* nearbyCell = (id)cell;
    MWKLocationSearchResult* result = object;
    nearbyCell.titleText = result.displayTitle;
    nearbyCell.descriptionText = result.wikidataDescription;
    nearbyCell.distance = result.distanceFromQueryCoordinates;
    nearbyCell.imageURL = result.thumbnailURL;
}

#pragma mark - Section Updates

- (void)updateSectionWithResults:(WMFLocationSearchResults*)results{
    
    [self.dataSource replaceItemsWithItems:results.results inSection:[self sectionIndex]];
}

- (void)updateSectionWithLocation:(CLLocation*)location{
    
    [[self.dataSource indexPathsOfItemsInSection:[self sectionIndex]] enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL *stop) {
        
        WMFHomeNearbyCell* cell = (id)[self.collectionView cellForItemAtIndexPath:obj];
        
        if(cell){
            MWKLocationSearchResult* result = [self.dataSource itemAtIndexPath:obj];
            cell.distance = [location distanceFromLocation:result.location];
        }
    }];
}

- (void)updateSectionWithHeading:(CLHeading*)heading{
    
    [[self.dataSource indexPathsOfItemsInSection:[self sectionIndex]] enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL *stop) {
        
        WMFHomeNearbyCell* cell = (id)[self.collectionView cellForItemAtIndexPath:obj];
        
        if(cell){
            MWKLocationSearchResult* result = [self.dataSource itemAtIndexPath:obj];
            cell.headingAngle = [self headingAngleToLocation:result.location startLocationLocation:self.locationManager.lastLocation heading:heading interfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
            
        }
    }];
}

- (void)updateSectionWithLocationError:(NSError*)error{
    
}

- (void)updateSectionWithSearchError:(NSError*)error{
    
}

#pragma mark - WMFNearbyControllerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location{
    [self updateSectionWithLocation:location];
    [self fetchNearbyArticlesIfLocationHasSignificantlyChanged:location];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading{
    [self updateSectionWithHeading:heading];
}

- (void)nearbyController:(WMFLocationManager*)controller didfetchNearbyResults:(WMFLocationSearchResults*)results{
    [self updateSectionWithResults:results];
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error{
    [self updateSectionWithLocationError:error];
}

#pragma mark - Fetch Nearby Results

- (void)fetchNearbyArticlesIfLocationHasSignificantlyChanged:(CLLocation*)location{
    
    if(self.nearbyResults.location && [self.nearbyResults.location distanceFromLocation:location] < WMFMinimumDistanceBeforeRefetching){
        return;
    }
    
    [self fetchNearbyArticlesWithLocation:location];
}

- (void)fetchNearbyArticlesWithLocation:(CLLocation*)location{
    
    if(self.locationSearchFetcher.isFetching){
        return;
    }
    
    [self.locationSearchFetcher fetchArticlesWithLocation:location]
    .then(^(WMFLocationSearchResults* results){
        self.nearbyResults = results;
        [self updateSectionWithResults:results];
    })
    .catch(^(NSError* error){
        [self updateSectionWithSearchError:error];
    });
}

#pragma mark - Compass Heading

- (NSNumber*)headingAngleToLocation:(CLLocation*)toLocation startLocationLocation:(CLLocation*)startLocation heading:(CLHeading*)heading interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    
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
