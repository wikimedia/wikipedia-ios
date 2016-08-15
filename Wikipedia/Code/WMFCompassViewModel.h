//
//  WMFCompassViewModel.h
//  Wikipedia
//
//  Created by Corey Floyd on 1/22/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMFSearchResultDistanceProvider;
@class WMFSearchResultBearingProvider;
@class MWKLocationSearchResult;

NS_ASSUME_NONNULL_BEGIN

@interface WMFCompassViewModel : NSObject

#pragma mark - Updates

- (void)startUpdates;

- (void)stopUpdates;

#pragma mark - Value Providers

/**
 *  Create a bearing provider for the location of the search result at the specified index.
 *
 *  @param result The search result which the bearing should point to.
 *
 *  @return An object whose @c bearingToLocation property is automatically updated when the user's heading changes.
 */
- (WMFSearchResultDistanceProvider *)distanceProviderForResult:(MWKLocationSearchResult *)result;

/**
 *  Create a distance provider for the location of the search result at the specified index.
 *
 *  @param result The search result which the bearing should point to.
 *
 *  @return An object whose @c distanceToUser property is automatically updated when the user's location changes.
 */
- (WMFSearchResultBearingProvider *)bearingProviderForResult:(MWKLocationSearchResult *)result;

@end

NS_ASSUME_NONNULL_END