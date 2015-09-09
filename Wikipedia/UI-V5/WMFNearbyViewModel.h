//
//  WMFNearbyViewModel.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMFLocationManager;
@class WMFLocationSearchFetcher;
@class WMFLocationSearchResults;

NS_ASSUME_NONNULL_BEGIN

@class WMFNearbyViewModel;
@protocol WMFNearbyViewModelDelegate <NSObject>

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didUpdateResults:(WMFLocationSearchResults*)results;
- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error;

@end

@interface WMFNearbyViewModel : NSObject

@property (nonatomic, weak) id<WMFNearbyViewModelDelegate> delegate;

@property (nonatomic, strong) MWKSite* site;
@property (nonatomic, strong, nullable, readonly) WMFLocationSearchResults* locationSearchResults;

- (instancetype)initWithSite:(MWKSite*)site resultLimit:(NSUInteger)resultLimit;

- (instancetype)initWithSite:(MWKSite*)site
                 resultLimit:(NSUInteger)resultLimit
             locationManager:(WMFLocationManager*)locationManager
                     fetcher:(WMFLocationSearchFetcher*)locationSearchFetcher NS_DESIGNATED_INITIALIZER;

- (void)fetch;

@end

NS_ASSUME_NONNULL_END
