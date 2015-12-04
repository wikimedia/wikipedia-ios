//
//  WMFNearbyViewModel.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKTitle;
@class MWKSite;
@class WMFLocationManager;
@class WMFLocationSearchFetcher;
@class WMFLocationSearchResults;
@class WMFNearbyViewModel;
@class MWKLocationSearchResult;
@class WMFSearchResultDistanceProvider;
@class WMFSearchResultBearingProvider;
@class CLLocation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Object which displays location search results and errors.
 */
@protocol WMFNearbyViewModelDelegate <NSObject>

/**
 *  Invoked when a view model has fetched new search results for a location.
 *
 *  This can happen as a result of either:
 *
 *    - Site updates (e.g. user changes the Wiki to get results from)<br/>
 *    - The user's location changing a significant amount
 *
 *  @param viewModel The view model which was updated.
 *  @param results   The results of the fetch.
 */
- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didUpdateResults:(WMFLocationSearchResults*)results;

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error;


@optional

- (BOOL)nearbyViewModel:(WMFNearbyViewModel*)viewModel shouldFetchTitlesForLocation:(CLLocation*)location;

// TODO: separate callback for authorization prompts

@end

@interface WMFNearbyViewModel : NSObject

/**
 *  The view model's delegate.
 */
@property (nonatomic, weak, nullable) id<WMFNearbyViewModelDelegate> delegate;

/**
 *  The site which will be searched.
 *
 *  Setting this property will idempotently trigger another search for the current location using the new site.
 */
@property (nonatomic, strong) MWKSite* site;

/**
 *  The results of the latest search.
 */
@property (nonatomic, strong, nullable, readonly) WMFLocationSearchResults* locationSearchResults;

/**
 *  Initialize a view model with an optional location manager and its own private fetcher.
 *
 *  Passing @c nil for the @c locationManager will cause the view model to create its own.
 *
 *  @see -initWithSite:resultLimit:locationManager:fetcher:
 */
- (instancetype)initWithSite:(MWKSite*)site
                 resultLimit:(NSUInteger)resultLimit
             locationManager:(WMFLocationManager* __nullable)locationManager;

/**
 *  Initialize a new view model.
 *
 *  @param site                  The site to query for titles.
 *  @param resultLimit           How many results will be retrieved per request.
 *  @param locationManager       The object which manages location events, which will have its @c delegate set to the
 *                               view model.
 *  @param locationSearchFetcher The fetcher used to send location search requests.
 *
 *  @return A new view model.
 */
- (instancetype)initWithSite:(MWKSite*)site
                 resultLimit:(NSUInteger)resultLimit
             locationManager:(WMFLocationManager*)locationManager
                     fetcher:(WMFLocationSearchFetcher*)locationSearchFetcher NS_DESIGNATED_INITIALIZER;

#pragma mark - Updates

- (void)startUpdates;

- (void)stopUpdates;

#pragma mark - Value Providers

/**
 *  Create a bearing provider for the location of the search result at the specified index.
 *
 *  @param index The index of the search result which the bearing should point to.
 *
 *  @return An object whose @c bearingToLocation property is automatically updated when the user's heading changes.
 */
- (WMFSearchResultBearingProvider*)bearingProviderForResultAtIndex:(NSUInteger)index;

/**
 *  Create a distance provider for the location of the search result at the specified index.
 *
 *  @param index The index of the search result which the distance should be measured from.
 *
 *  @return An object whose @c distanceToUser property is automatically updated when the user's location changes.
 */
- (WMFSearchResultDistanceProvider*)distanceProviderForResultAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
