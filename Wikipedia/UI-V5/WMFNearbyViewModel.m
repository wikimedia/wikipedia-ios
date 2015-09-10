//
//  WMFNearbyViewModel.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFNearbyViewModel.h"

// Location & Fetching
#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"

// Models
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"
#import "MWKHistoryEntry.h"
#import "CLLocation+WMFApproximateEquality.h"
#import "CLLocation+WMFBearing.h"

// Frameworks
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

@interface WMFNearbyViewModel ()
<WMFNearbyControllerDelegate>

@property (nonatomic, strong) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, assign) NSUInteger resultLimit;

@property (nonatomic, strong, readwrite) WMFLocationSearchResults* locationSearchResults;

@property (nonatomic, strong) NSMutableIndexSet* autoUpdatingIndexes;

@end

@implementation WMFNearbyViewModel

- (instancetype)initWithSite:(MWKSite*)site
                 resultLimit:(NSUInteger)resultLimit
             locationManager:(WMFLocationManager* __nullable)locationManager {
    return [self initWithSite:site
                  resultLimit:resultLimit
              locationManager:locationManager ? : [[WMFLocationManager alloc] init]
                      fetcher:[[WMFLocationSearchFetcher alloc] init]];
}

- (instancetype)initWithSite:(MWKSite*)site
                 resultLimit:(NSUInteger)resultLimit
             locationManager:(WMFLocationManager*)locationManager
                     fetcher:(WMFLocationSearchFetcher*)locationSearchFetcher {
    self = [super init];
    if (self) {
        self.autoUpdatingIndexes   = [NSMutableIndexSet indexSet];
        self.site                  = site;
        self.resultLimit           = resultLimit;
        self.locationSearchFetcher = locationSearchFetcher;
        // !!!: Must setup location manager last to prevent delegate callbacks firing before fetcher is setup
        self.locationManager          = locationManager;
        self.locationManager.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [self stopUpdates];
}

- (void)setSite:(MWKSite* __nonnull)site {
    if (WMF_EQUAL(self.site, isEqualToSite:, site)) {
        return;
    }
    _site = site;
    [self fetchTitlesForLocation:self.locationSearchResults.location];
}

- (void)setLocationSearchResults:(WMFLocationSearchResults* __nullable)locationSearchResults {
    if (WMF_EQUAL(self.locationSearchResults, isEqual:, locationSearchResults)) {
        return;
    }
    [self stopUpdatingAllResults];
    _locationSearchResults = locationSearchResults;
}

#pragma mark - Result Updates

- (void)autoUpdateResultAtIndex:(NSUInteger)index {
    [self.autoUpdatingIndexes addIndex:index];
    DDLogInfo(@"Tracking headings for %lu indexes", self.autoUpdatingIndexes.count);
    [self updateBearingAtIndex:index];
    [self updateDistanceAtIndex:index];
}

- (void)stopUpdatingResultAtIndex:(NSUInteger)index {
    [self.autoUpdatingIndexes removeIndex:index];
    DDLogInfo(@"Tracking headings for %lu indexes", self.autoUpdatingIndexes.count);
    // TODO: toggle heading tracking based on whether or not we have indexes to track
}

- (void)stopUpdatingAllResults {
    [self.autoUpdatingIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* stop) {
        [self stopUpdatingResultAtIndex:idx];
    }];
}

- (void)updateBearingAtIndex:(NSUInteger)index {
    MWKLocationSearchResult* result = self.locationSearchResults.results[index];
    result.bearingToLocation =
        [self.locationSearchResults.location wmf_bearingToLocation:result.location
                                                 forCurrentHeading:self.locationManager.lastHeading];
}

- (void)updateDistanceAtIndex:(NSUInteger)index {
    MWKLocationSearchResult* result = self.locationSearchResults.results[index];
    result.distanceFromUser = [result.location distanceFromLocation:self.locationManager.lastLocation];
}

#pragma mark - Fetch

- (void)startUpdates {
    [self.locationManager restartLocationMonitoring];
    // TODO: check if authorized. if not, fail w/ an error
}

- (void)stopUpdates {
    [self.locationManager stopMonitoringLocation];
    self.locationSearchResults = nil;
    // TODO: cancel last search request
}

- (void)fetchTitlesForLocation:(CLLocation* __nullable)location {
    if (!location) {
        return;
    } else if ([self.locationSearchResults.location distanceFromLocation:location] < 500
               && [self.locationSearchResults.searchSite isEqualToSite:self.site]) {
        /*
           How often we search titles for a location is separate from how often the location updates.
           See WMFLocationManager for distanceFilter settings.
         */
        DDLogVerbose(@"Not fetching nearby titles for %@ since it is too close to previously fetched location: %@.",
                     location, self.locationSearchResults.location);
        return;
    }

    NSAssert(![self.locationSearchResults.location wmf_isVeryCloseToLocation:location]
             || self.locationSearchResults.searchSite,
             @"Unexpected fetch of two nearly adjacent locations: %@", @[self.locationSearchResults.location, location]);

    // TODO: cancel fetch for previous location
    @weakify(self);
    [self.locationSearchFetcher fetchArticlesWithSite:self.site location:location resultLimit:self.resultLimit]
    .then(^(WMFLocationSearchResults* locationSearchResults) {
        @strongify(self);
        if (![locationSearchResults.searchSite isEqualToSite:self.site]) {
            DDLogWarn(@"Ignoring location search results from site %@ since it was changed to %@",
                      locationSearchResults.searchSite, self.site);
            return;
        } else if (![locationSearchResults.location wmf_hasSameCoordinatesAsLocation:self.locationManager.lastLocation]) {
            DDLogWarn(@"Ignoring location search results for location %@ since it was updated to %@",
                      locationSearchResults.location, self.locationManager.lastLocation);
            return;
        }
        self.locationSearchResults = locationSearchResults;
        [self.delegate nearbyViewModel:self didUpdateResults:locationSearchResults];
    })
    .catch(^(NSError* error) {
        @strongify(self);
        [self.delegate nearbyViewModel:self didFailWithError:error];
    });
}

#pragma mark - WMFNearbyControllerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    [self fetchTitlesForLocation:location];
    [self.autoUpdatingIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* _) {
        [self updateDistanceAtIndex:idx];
    }];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
    [self.autoUpdatingIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* _) {
        [self updateBearingAtIndex:idx];
    }];
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
    [self.delegate nearbyViewModel:self didFailWithError:error];
}

@end
