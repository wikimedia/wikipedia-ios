//
//  WMFNearbyTitleListDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFNearbyTitleListDataSource.h"

// Location & Fetching
#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"

// Models
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"
#import "MWKHistoryEntry.h"

// Frameworks
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

// Views
#import "WMFHomeNearbyCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFArticlePreviewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbyTitleListDataSource ()
<WMFNearbyControllerDelegate>

@property (nonatomic, strong) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) WMFLocationSearchResults* locationSearchResults;

@end

@implementation WMFNearbyTitleListDataSource

- (instancetype)initWithSite:(MWKSite*)site {
    return [self initWithSite:site
              locationManager:[[WMFLocationManager alloc] init]
                      fetcher:[[WMFLocationSearchFetcher alloc] init]];
}

- (instancetype)initWithSite:(MWKSite*)site
             locationManager:(WMFLocationManager*)locationManager
                     fetcher:(WMFLocationSearchFetcher*)locationSearchFetcher {
    self = [super initWithItems:nil];
    if (self) {
        self.site                  = site;
        self.locationSearchFetcher = locationSearchFetcher;

        self.cellClass = [WMFHomeNearbyCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFHomeNearbyCell* nearbyCell,
                                    MWKArticle* article,
                                    id parentView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKLocationSearchResult* result = self.locationSearchResults.results[indexPath.item];
            [nearbyCell setSavedPageList:self.savedPageList];
            nearbyCell.descriptionText = result.wikidataDescription;
            nearbyCell.title           = article.title;
            nearbyCell.distance        = result.distanceFromQueryCoordinates;
            nearbyCell.imageURL        = result.thumbnailURL;
        };

        // !!!: Need to setup location manager last to prevent premature delegate callbacks
        self.locationManager          = locationManager;
        self.locationManager.delegate = self;
        [self.locationManager restartLocationMonitoring];
    }
    return self;
}

- (void)setLocationSearchResults:(WMFLocationSearchResults* __nonnull)locationSearchResults {
    if (locationSearchResults == self.locationSearchResults) {
        return;
    }
    _locationSearchResults = locationSearchResults;

    [self updateItems:[_locationSearchResults.results bk_map:^MWKArticle*(MWKLocationSearchResult* locResult) {
        MWKTitle* title = [[MWKTitle alloc] initWithString:locResult.displayTitle site:self.site];
        NSError* error;
        NSDictionary* serializedSearchResult = [MTLJSONAdapter JSONDictionaryFromModel:locResult error:&error];
        NSAssert(serializedSearchResult, @"Failed to serialize location search result %@. Error %@", locResult, error);
        MWKArticle* article = [[MWKArticle alloc] initWithTitle:title
                                                      dataStore:nil
                                              searchResultsDict:serializedSearchResult];
        return article;
    }]];
}

- (void)setSite:(MWKSite* __nonnull)site {
    if (WMF_EQUAL(self.site, isEqualToSite:, site)) {
        return;
    }
    _site = site;
    if (self.locationSearchResults && ![self.locationSearchResults.searchSite isEqualToSite:self.site]) {
        DDLogInfo(@"Search site changed, reloading nearby titles.");
        [self fetchTitlesForLocation:self.locationSearchResults.location];
    }
}

- (void)fetchTitlesForUpdatedLocationIfNeeded:(CLLocation*)location {
    if (!self.locationSearchResults
        || [self.locationSearchResults.location distanceFromLocation:location] > 500) {
        DDLogInfo(@"Fetching nearby titles for new location %@, last location %@",
                  location, self.locationSearchResults.location);
        [self fetchTitlesForLocation:location];
    }
}

- (void)fetchTitlesForLocation:(CLLocation*)location {
    @weakify(self);
    [self.locationSearchFetcher fetchArticlesWithSite:self.site location:location resultLimit:20]
    .then(^(WMFLocationSearchResults* locationSearchResults) {
        @strongify(self);
        self.locationSearchResults = locationSearchResults;
    });
}

#pragma mark - WMFArticleListDataSource

- (NSString* __nullable)displayTitle {
    // TODO: localize & standardize w/ home section controller
    return @"More from nearby your location";
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath* __nonnull)indexPath {
    return NO;
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (NSArray*)articles {
    return self.allItems;
}

- (NSUInteger)articleCount {
    return self.allItems.count;
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath* __nonnull)indexPath {
    return [self itemAtIndexPath:indexPath];
}

- (NSIndexPath*)indexPathForArticle:(MWKArticle* __nonnull)article {
    return [self indexPathForItem:article];
}

#pragma mark - SSDataSource

- (void)setCollectionView:(UICollectionView*)collectionView {
    [super setCollectionView:collectionView];
    [collectionView registerNib:[WMFHomeNearbyCell wmf_classNib]
     forCellWithReuseIdentifier:[WMFHomeNearbyCell identifier]];
}

#pragma mark - WMFNearbyControllerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    [self fetchTitlesForUpdatedLocationIfNeeded:location];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
    #warning TODO: update headings
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
}

@end

NS_ASSUME_NONNULL_END
