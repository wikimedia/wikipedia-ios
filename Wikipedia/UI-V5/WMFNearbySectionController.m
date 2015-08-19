
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
    [self fetchNearbyArticlesWithLocation:location];
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

- (void)fetchNearbyArticlesWithLocation:(CLLocation*)location{
    
    [self.locationSearchFetcher fetchArticlesWithLocation:location]
    .then(^(WMFLocationSearchResults* results){
        self.nearbyResults = results;
        [self updateSectionWithResults:results];
    })
    .catch(^(NSError* error){
        [self updateSectionWithSearchError:error];
    });
}



@end
