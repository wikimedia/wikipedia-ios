//
//  WMFNearbyTitleListDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFNearbyTitleListDataSource.h"

// View Model
#import "WMFNearbyViewModel.h"

// Models
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKLocationSearchResult.h"
#import "MWKArticle.h"
#import "WMFLocationSearchResults.h"
#import "MWKHistoryEntry.h"

// Views
#import "WMFNearbyArticleTableViewCell.h"
#import "UIView+WMFDefaultNib.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFNearbyTitleListDataSource ()
<WMFNearbyViewModelDelegate>

@property (nonatomic, strong) WMFNearbyViewModel* viewModel;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@end

@implementation WMFNearbyTitleListDataSource

- (instancetype)initWithSite:(MWKSite*)site {
    WMFNearbyViewModel* viewModel = [[WMFNearbyViewModel alloc] initWithSite:site
                                                                 resultLimit:20
                                                             locationManager:nil];
    return [self initWithSite:site viewModel:viewModel];
}

- (instancetype)initWithSite:(MWKSite*)site viewModel:(WMFNearbyViewModel*)viewModel {
    NSParameterAssert([viewModel.site isEqualToSite:site]);
    self = [super initWithItems:nil];
    if (self) {
        self.cellClass = [WMFNearbyArticleTableViewCell class];
        @weakify(self);
        self.cellConfigureBlock = ^(WMFNearbyArticleTableViewCell* nearbyCell,
                                    MWKLocationSearchResult* result,
                                    id parentView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            nearbyCell.titleText       = result.displayTitle;
            nearbyCell.descriptionText = result.wikidataDescription;
            [nearbyCell setImageURL:result.thumbnailURL];
            [nearbyCell setDistanceProvider:[self.viewModel distanceProviderForResultAtIndex:indexPath.item]];
            [nearbyCell setBearingProvider:[self.viewModel bearingProviderForResultAtIndex:indexPath.item]];
        };
        self.viewModel          = viewModel;
        self.viewModel.delegate = self;
    }
    return self;
}

- (void)setTableView:(nullable UITableView*)tableView {
    [super setTableView:tableView];
    [self.tableView registerNib:[WMFNearbyArticleTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFNearbyArticleTableViewCell identifier]];
}

- (void)setSite:(MWKSite* __nonnull)site {
    self.viewModel.site = site;
}

- (MWKSite*)site {
    return self.viewModel.site;
}

#pragma mark - WMFArticleListDynamicDataSource

- (NSString* __nullable)displayTitle {
    return MWLocalizedString(@"main-menu-nearby", nil);
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath* __nonnull)indexPath {
    return NO;
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (NSArray*)titles {
    return [self.viewModel.locationSearchResults.results bk_map:^id (MWKLocationSearchResult* obj) {
        return [self.site titleWithString:obj.displayTitle];
    }];
}

- (NSUInteger)titleCount {
    return self.viewModel.locationSearchResults.results.count;
}

- (MWKLocationSearchResult*)searchResultForIndexPath:(NSIndexPath*)indexPath {
    MWKLocationSearchResult* result = self.viewModel.locationSearchResults.results[indexPath.row];
    return result;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKLocationSearchResult* result = [self searchResultForIndexPath:indexPath];
    return [self.site titleWithString:result.displayTitle];
}

- (void)startUpdating {
    [self.viewModel startUpdates];
}

- (void)stopUpdating {
    [self.viewModel stopUpdates];
}

#pragma mark - WMFNearbyViewModelDelegate

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error {
    // TODO: propagate error to view controller
}

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel
       didUpdateResults:(WMFLocationSearchResults*)locationSearchResults {
    // TEMP: remove this when artilce lists can handle article placeholders

    [self updateItems:locationSearchResults.results];
}

- (BOOL)nearbyViewModel:(WMFNearbyViewModel*)viewModel shouldFetchTitlesForLocation:(CLLocation*)location {
    return [self numberOfItems] == 0;
}

- (NSString*)analyticsName {
    return @"Nearby";
}

@end

NS_ASSUME_NONNULL_END
