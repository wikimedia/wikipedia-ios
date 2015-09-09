//
//  WMFNearbyTitleListDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <SSDataSources/SSArrayDataSource.h>
#import "WMFArticleListDataSource.h"

@class CLLocation;
@class WMFLocationManager;
@class WMFLocationSearchFetcher;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbyTitleListDataSource : SSArrayDataSource
    <WMFArticleListDataSource>

@property (nonatomic, strong) MWKSite* site;

- (instancetype)initWithSite:(MWKSite*)site;

- (instancetype)initWithSite:(MWKSite*)site
             locationManager:(WMFLocationManager*)locationManager
                     fetcher:(WMFLocationSearchFetcher*)locationSearchFetcher NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
