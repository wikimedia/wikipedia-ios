//
//  WMFRelatedTitleListDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFRelatedTitleListDataSource.h"

// Frameworks
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

// View
#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"

// Fetcher
#import "WMFRelatedSearchFetcher.h"

// Model
#import "MWKTitle.h"
#import "MWKArticle.h"
#import "MWKRelatedSearchResult.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryEntry.h"
#import "MWKDataStore.h"
#import "WMFRelatedSearchResults.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedTitleListDataSource ()

@property (nonatomic, copy) MWKTitle* title;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) WMFRelatedSearchFetcher* relatedSearchFetcher;
@property (nonatomic, assign) NSUInteger numberOfExtractCharacters;

@property (nonatomic, copy) NSArray* relatedTitleResults;

@end

@implementation WMFRelatedTitleListDataSource


- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                savedPageList:(MWKSavedPageList*)savedPageList
    numberOfExtractCharacters:(NSUInteger)numberOfExtractCharacters {
    return [self initWithTitle:title
                            dataStore:dataStore
                        savedPageList:savedPageList
            numberOfExtractCharacters:numberOfExtractCharacters
                              fetcher:[[WMFRelatedSearchFetcher alloc] init]];
}

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                savedPageList:(MWKSavedPageList*)savedPageList
    numberOfExtractCharacters:(NSUInteger)numberOfExtractCharacters
                      fetcher:(WMFRelatedSearchFetcher*)fetcher {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    NSParameterAssert(savedPageList);
    NSParameterAssert(fetcher);
    self = [super initWithItems:nil];
    if (self) {
        self.title                     = title;
        self.dataStore                 = dataStore;
        self.savedPageList             = savedPageList;
        self.numberOfExtractCharacters = numberOfExtractCharacters;
        self.relatedSearchFetcher      = fetcher;

        self.cellClass = [WMFArticlePreviewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticlePreviewCell* cell,
                                    MWKArticle* article,
                                    UICollectionView* collectionView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKRelatedSearchResult* searchResult = self.relatedTitleResults[indexPath.item];
            [cell setSavedPageList:self.savedPageList];
            cell.title           = article.title;
            cell.descriptionText = searchResult.wikidataDescription;
            cell.image           = [article bestThumbnailImage];
            [cell setSummaryHTML:searchResult.extractHTML fromSite:self.title.site];
        };
    }
    return self;
}

- (void)setCollectionView:(UICollectionView*)collectionView {
    [super setCollectionView:collectionView];
    [self.collectionView registerNib:[WMFArticlePreviewCell wmf_classNib]
          forCellWithReuseIdentifier:[WMFArticlePreviewCell identifier]];
}

#pragma mark - Fetching

- (AnyPromise*)fetch {
    @weakify(self);
    return [self.relatedSearchFetcher fetchArticlesRelatedToTitle:self.title
                                         numberOfExtactCharacters:self.numberOfExtractCharacters
                                                      resultLimit:WMFMaxRelatedSearchResultLimit]
           .then(^(WMFRelatedSearchResults* searchResults) {
        @strongify(self);
        if (!self) {
            return;
        }
        NSMutableArray* mutableResults = [searchResults.results mutableCopy];
        NSArray* items = [mutableResults bk_reduce:[NSMutableArray arrayWithCapacity:self.relatedTitleResults.count]
                                         withBlock:^(NSMutableArray* articles,
                                                     MWKRelatedSearchResult* relatedSearchResult) {
            MWKTitle* title = [[MWKTitle alloc] initWithString:relatedSearchResult.displayTitle
                                                          site:self.title.site];
            NSError* error;
            NSDictionary* resultJSON = [MTLJSONAdapter JSONDictionaryFromModel:relatedSearchResult error:&error];
            if (!resultJSON) {
                DDLogError(@"Unexpected error re-serializing search result %@. Error: %@",
                           relatedSearchResult, error);
                [mutableResults removeObject:relatedSearchResult];
                return articles;
            }
            MWKArticle* article = [[MWKArticle alloc]
                                   initWithTitle:title
                                        dataStore:self.dataStore
                                searchResultsDict:resultJSON];
            [articles addObject:article];
            return articles;
        }];
        self.relatedTitleResults = [mutableResults copy];;
        [self updateItems:items];
    });
}

#pragma mark - WMFArticleListDataSource

- (NSIndexPath*)indexPathForArticle:(MWKArticle*)article {
    return [NSIndexPath indexPathForItem:[self.allItems indexOfObject:article] inSection:0];
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    return self.allItems[indexPath.item];
}

- (NSArray*)articles {
    return self.allItems;
}

- (NSUInteger)articleCount {
    return self.allItems.count;
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (nullable NSString*)displayTitle {
    // TODO: localize
    return [NSString stringWithFormat:@"More like %@", self.title.text];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath* __nonnull)indexPath {
    return NO;
}

@end

NS_ASSUME_NONNULL_END
