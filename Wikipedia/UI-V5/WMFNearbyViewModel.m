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

// Frameworks
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

@interface WMFNearbyViewModel ()
<WMFNearbyControllerDelegate>

@property (nonatomic, strong) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, assign) NSUInteger resultLimit;

@property (nonatomic, strong, readwrite) WMFLocationSearchResults* locationSearchResults;

@end

@implementation WMFNearbyViewModel

- (instancetype)initWithSite:(MWKSite*)site resultLimit:(NSUInteger)resultLimit {
    return [self initWithSite:site
                  resultLimit:resultLimit
              locationManager:[[WMFLocationManager alloc] init]
                      fetcher:[[WMFLocationSearchFetcher alloc] init]];
}

- (instancetype)initWithSite:(MWKSite*)site
                 resultLimit:(NSUInteger)resultLimit
             locationManager:(WMFLocationManager*)locationManager
                     fetcher:(WMFLocationSearchFetcher*)locationSearchFetcher {
    self = [super init];
    if (self) {
        self.site                  = site;
        self.resultLimit           = resultLimit;
        self.locationSearchFetcher = locationSearchFetcher;
        // !!!: Must setup location manager last to prevent delegate callbacks firing before fetcher is setup
        self.locationManager          = locationManager;
        self.locationManager.delegate = self;
    }
    return self;
}

- (void)setSite:(MWKSite* __nonnull)site {
    if (WMF_EQUAL(self.site, isEqualToSite:, site)) {
        return;
    }
    _site = site;
    [self fetchTitlesForLocation:self.locationSearchResults.location];
}

#pragma mark - Fetch

- (void)fetch {
    [self.locationManager restartLocationMonitoring];
    // TODO: check if authorized. if not, fail w/ an error
}

- (void)fetchTitlesForLocation:(CLLocation* __nullable)location {
    if (!location) {
        return;
    } else if ([self.locationSearchResults.location wmf_hasSameCoordinatesAsLocation:location]
        && [self.locationSearchResults.searchSite isEqualToSite:self.site]) {
        /*
         HAX: CLLocationManger will send redundant updates (same location w/ a different timestamp) even if the
         distance filter is set to a large number.
        */
        DDLogInfo(@"Ignoring fetch request for %@ since it is too close to previously fetched location: %@",
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
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
    #warning TODO: update headings
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
    [self.delegate nearbyViewModel:self didFailWithError:error];
}

@end
