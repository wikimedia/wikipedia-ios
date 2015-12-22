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
#import "WMFSearchResultDistanceProvider.h"
#import "WMFSearchResultBearingProvider.h"
#import "MWKSite.h"

// Frameworks
#import "Wikipedia-Swift.h"

@interface WMFNearbyViewModel ()
<WMFLocationManagerDelegate>

@property (nonatomic, strong) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, assign) NSUInteger resultLimit;

@property (nonatomic, strong, readwrite) WMFLocationSearchResults* locationSearchResults;

@property (nonatomic, weak) id<Cancellable> lastFetch;

#pragma mark - Location Manager State

/**
 *  @name Location Manager State
 *
 *  We need to keep track of these properties to ensure that the UI isn't emptied if the location manager is restarted,
 *  which will temporarily set its @c location and @c heading properties to @c nil.
 */

/**
 *  The last-known location reported by the @c locationManager.
 */
@property (nonatomic, strong, readwrite, nullable) CLLocation* lastLocation;

/**
 *  The last-known heading reported by the @c locationManager.
 */
@property (nonatomic, strong, readwrite, nullable) CLHeading* lastHeading;

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
        self.site                  = site;
        self.resultLimit           = resultLimit;
        self.locationSearchFetcher = locationSearchFetcher;
        // !!!: Must setup location manager last to prevent delegate callbacks firing before fetcher is setup
        self.locationManager          = locationManager;
        self.locationManager.delegate = self;
        self.lastLocation             = self.locationManager.location;
        self.lastHeading              = self.locationManager.heading;
    }
    return self;
}

- (void)setSite:(MWKSite*)site {
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
    NSParameterAssert(!locationSearchResults || [locationSearchResults.searchSite isEqualToSite:self.site]);
    _locationSearchResults = locationSearchResults;
}

- (void)setLastHeading:(CLHeading* __nullable)lastHeading {
    if (!lastHeading) {
        // ignore nil values to keep last known heading on the screen
        return;
    }
    _lastHeading = lastHeading;
}

- (void)setLastLocation:(CLLocation* __nullable)lastLocation {
    if (!lastLocation) {
        // ignore nil values to keep last known heading on the screen
        return;
    }
    _lastLocation = lastLocation;
    [self fetchTitlesForLocation:_lastLocation];
}

#pragma mark - Fetch

- (void)startUpdates {
    [self.locationManager startMonitoringLocation];
}

- (void)stopUpdates {
    [self.locationManager stopMonitoringLocation];
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
    } else if ([self.delegate respondsToSelector:@selector(nearbyViewModel:shouldFetchTitlesForLocation:)]
               && ![self.delegate nearbyViewModel:self shouldFetchTitlesForLocation:location]) {
        DDLogInfo(@"Skipping title update for new location %@", location);
        return;
    }

    [self.lastFetch cancel];
    id<Cancellable> fetch;
    @weakify(self);
    [self.locationSearchFetcher fetchArticlesWithSite:self.site
                                             location:location
                                          resultLimit:self.resultLimit
                                          cancellable:&fetch]
    .then(^(WMFLocationSearchResults* locationSearchResults) {
        @strongify(self);
        self.locationSearchResults = locationSearchResults;
        [self.delegate nearbyViewModel:self didUpdateResults:locationSearchResults];
    })
    .catch(^(NSError* error) {
        @strongify(self);
        [self.delegate nearbyViewModel:self didFailWithError:error];
    });
    self.lastFetch = fetch;
}

#pragma mark - Value Providers

- (WMFSearchResultDistanceProvider*)distanceProviderForResultAtIndex:(NSUInteger)index {
    WMFSearchResultDistanceProvider* provider = [WMFSearchResultDistanceProvider new];
    MWKLocationSearchResult* result           = self.locationSearchResults.results[index];
    [provider.KVOController
     observe:self
     keyPath:WMF_SAFE_KEYPATH(self, lastLocation)
     options:NSKeyValueObservingOptionInitial
       block:^(WMFSearchResultDistanceProvider* observer, WMFNearbyViewModel* nearbyViewModel, NSDictionary* _) {
        observer.distanceToUser = [result.location distanceFromLocation:nearbyViewModel.lastLocation];
    }];
    return provider;
}

- (WMFSearchResultBearingProvider*)bearingProviderForResultAtIndex:(NSUInteger)index {
    WMFSearchResultBearingProvider* provider = [WMFSearchResultBearingProvider new];
    MWKLocationSearchResult* result          = self.locationSearchResults.results[index];
    [provider.KVOController
     observe:self
     keyPath:WMF_SAFE_KEYPATH(self, lastHeading)
     options:NSKeyValueObservingOptionInitial
       block:^(WMFSearchResultBearingProvider* observer, WMFNearbyViewModel* viewModel, NSDictionary* _) {
        observer.bearingToLocation =
            [viewModel.lastLocation wmf_bearingToLocation:result.location
                                        forCurrentHeading:viewModel.lastHeading];
    }];
    return provider;
}

#pragma mark - WMFNearbyControllerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    self.lastLocation = location;
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
    self.lastHeading = heading;
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
    [self.delegate nearbyViewModel:self didFailWithError:error];
}

@end
