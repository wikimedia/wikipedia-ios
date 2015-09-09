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

// Views
#import "WMFHomeNearbyCell.h"
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
    WMFNearbyViewModel* viewModel = [[WMFNearbyViewModel alloc] initWithSite:site resultLimit:20];
    return [self initWithSite:site viewModel:viewModel];
}

- (instancetype)initWithSite:(MWKSite*)site viewModel:(WMFNearbyViewModel*)viewModel {
    NSParameterAssert([viewModel.site isEqualToSite:site]);
    self = [super initWithItems:nil];
    if (self) {
        self.cellClass = [WMFHomeNearbyCell class];
        @weakify(self);
        self.cellConfigureBlock = ^(WMFHomeNearbyCell* nearbyCell,
                                    MWKArticle* article,
                                    id parentView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKLocationSearchResult* result = self.viewModel.locationSearchResults.results[indexPath.item];
            [nearbyCell setSavedPageList:self.savedPageList];
            nearbyCell.descriptionText = result.wikidataDescription;
            nearbyCell.title           = article.title;
            nearbyCell.distance        = result.distanceFromQueryCoordinates;
            nearbyCell.imageURL        = result.thumbnailURL;
        };
        self.viewModel = viewModel;
        self.viewModel.delegate = self;
        [self.viewModel fetch];
    }
    return self;
}

- (void)setSite:(MWKSite * __nonnull)site {
    self.viewModel.site = site;
}

- (MWKSite*)site {
    return self.viewModel.site;
}

#pragma mark - WMFArticleListDataSource

- (NSString* __nullable)displayTitle {
    // TODO: localize & standardize w/ home section controller
    return @"More from nearby your location";
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

#pragma mark - SSDataSource

- (void)setCollectionView:(UICollectionView*)collectionView {
    [super setCollectionView:collectionView];
    [collectionView registerNib:[WMFHomeNearbyCell wmf_classNib]
     forCellWithReuseIdentifier:[WMFHomeNearbyCell identifier]];
}

#pragma mark - WMFNearbyViewModelDelegate

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel didFailWithError:(NSError*)error {
    // TODO: propagate error to view controller
}

- (void)nearbyViewModel:(WMFNearbyViewModel*)viewModel
       didUpdateResults:(WMFLocationSearchResults*)locationSearchResults {
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
