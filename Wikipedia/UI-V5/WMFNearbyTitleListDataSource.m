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
#import "WMFNearbySearchResultCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFArticlePreviewCell.h"

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
        self.cellClass = [WMFNearbySearchResultCell class];
        @weakify(self);
        self.cellConfigureBlock = ^(WMFNearbySearchResultCell* nearbyCell,
                                    MWKArticle* article,
                                    id parentView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKLocationSearchResult* result = self.viewModel.locationSearchResults.results[indexPath.item];
            [nearbyCell setSavedPageList:self.savedPageList];
            [nearbyCell setTitle:[self.viewModel.locationSearchResults titleForResult:result]];
            [nearbyCell setSearchResultDescription:result.wikidataDescription];
            [nearbyCell setImageURL:result.thumbnailURL];
            [nearbyCell setSavedPageList:self.savedPageList];
            [nearbyCell setDistanceProvider:[self.viewModel distanceProviderForResultAtIndex:indexPath.item]];
            [nearbyCell setBearingProvider:[self.viewModel bearingProviderForResultAtIndex:indexPath.item]];
        };
        self.viewModel          = viewModel;
        self.viewModel.delegate = self;
    }
    return self;
}

- (void)setSite:(MWKSite* __nonnull)site {
    self.viewModel.site = site;
}

- (MWKSite*)site {
    return self.viewModel.site;
}

#pragma mark - WMFArticleListDynamicDataSource

- (NSString* __nullable)displayTitle {
    // TODO: localize
    return @"Nearby";
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

- (void)startUpdating {
    [self.viewModel startUpdates];
}

- (void)stopUpdating {
    [self.viewModel stopUpdates];
}

#pragma mark - SSDataSource

- (void)setCollectionView:(UICollectionView* __nullable)collectionView {
    [super setCollectionView:collectionView];
    [collectionView registerNib:[WMFNearbySearchResultCell wmf_classNib]
     forCellWithReuseIdentifier:[WMFNearbySearchResultCell identifier]];
}

#pragma mark - WMFNearbyViewModelDelegate

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error {
    // TODO: propagate error to view controller
}

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel
       didUpdateResults:(WMFLocationSearchResults*)locationSearchResults {
    // TEMP: remove this when artilce lists can handle article placeholders
    [self updateItems:[locationSearchResults.results bk_map:^MWKArticle*(MWKLocationSearchResult* locResult) {
        MWKTitle* title = [[MWKTitle alloc] initWithString:locResult.displayTitle
                                                      site:locationSearchResults.searchSite];
        NSError* error;
        NSDictionary* serializedSearchResult = [MTLJSONAdapter JSONDictionaryFromModel:locResult error:&error];
        NSAssert(serializedSearchResult, @"Failed to serialize location search result %@. Error %@", locResult, error);
        MWKArticle* article = [[MWKArticle alloc] initWithTitle:title
                                                      dataStore:nil
                                              searchResultsDict:serializedSearchResult];
        return article;
    }]];
}

@end

NS_ASSUME_NONNULL_END
