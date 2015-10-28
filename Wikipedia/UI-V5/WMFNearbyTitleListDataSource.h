//
//  WMFNearbyTitleListDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <SSDataSources/SSArrayDataSource.h>
#import "WMFTitleListDataSource.h"

@class WMFNearbyViewModel, WMFLocationManager, MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbyTitleListDataSource : SSArrayDataSource
    <WMFArticleListDynamicDataSource>

@property (nonatomic, strong) MWKSite* site;

- (instancetype)initWithSite:(MWKSite*)site;

- (instancetype)initWithSite:(MWKSite*)site
                   viewModel:(WMFNearbyViewModel*)viewModel NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
