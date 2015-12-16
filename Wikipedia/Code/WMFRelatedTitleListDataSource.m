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

// View
#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"

// Fetcher
#import "WMFRelatedSearchFetcher.h"

// Model
#import "MWKTitle.h"
#import "MWKArticle.h"
#import "MWKSearchResult.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryEntry.h"
#import "MWKDataStore.h"
#import "WMFRelatedSearchResults.h"
#import "WMFSaveButtonController.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedTitleListDataSource ()

@property (nonatomic, copy) MWKTitle* title;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) WMFRelatedSearchFetcher* relatedSearchFetcher;
@property (nonatomic, strong, readwrite, nullable) WMFRelatedSearchResults* relatedSearchResults;

@property (nonatomic, assign) NSUInteger resultLimit;

@end

@implementation WMFRelatedTitleListDataSource

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                savedPageList:(MWKSavedPageList*)savedPageList
                  resultLimit:(NSUInteger)resultLimit {
    return [self initWithTitle:title
                     dataStore:dataStore
                 savedPageList:savedPageList
                   resultLimit:resultLimit
                       fetcher:[[WMFRelatedSearchFetcher alloc] init]];
}

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                savedPageList:(MWKSavedPageList*)savedPageList
                  resultLimit:(NSUInteger)resultLimit
                      fetcher:(WMFRelatedSearchFetcher*)fetcher {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    NSParameterAssert(savedPageList);
    NSParameterAssert(fetcher);
    self = [super initWithItems:nil];
    if (self) {
        self.title                = title;
        self.dataStore            = dataStore;
        self.savedPageList        = savedPageList;
        self.relatedSearchFetcher = fetcher;
        self.resultLimit          = resultLimit;

        self.cellClass = [WMFArticlePreviewTableViewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticlePreviewTableViewCell* cell,
                                    MWKSearchResult* searchResult,
                                    UITableView* tableView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKTitle* title = [self.title.site titleWithString:searchResult.displayTitle];
            [cell setSaveableTitle:title savedPageList:self.savedPageList];
            cell.titleText       = searchResult.displayTitle;
            cell.descriptionText = searchResult.wikidataDescription;
            cell.snippetText     = searchResult.extract;
            [cell setImageURL:searchResult.thumbnailURL];
            [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
            cell.saveButtonController.analyticsSource = self;
        };
    }
    return self;
}

- (void)setTableView:(nullable UITableView*)tableView {
    [super setTableView:tableView];
    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
}

#pragma mark - Fetching

- (AnyPromise*)fetch {
    @weakify(self);
    return [self.relatedSearchFetcher fetchArticlesRelatedToTitle:self.title
                                                      resultLimit:self.resultLimit]
           .then(^(WMFRelatedSearchResults* searchResults) {
        @strongify(self);
        if (!self) {
            return (id)nil;
        }
        self.relatedSearchResults = searchResults;
        [self updateItems:searchResults.results];
        return (id)searchResults;
    });
}

#pragma mark - WMFArticleListDataSource

- (MWKSearchResult*)searchResultForIndexPath:(NSIndexPath*)indexPath {
    MWKSearchResult* result = self.relatedSearchResults.results[indexPath.row];
    return result;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKSearchResult* result = [self searchResultForIndexPath:indexPath];
    return [self.title.site titleWithString:result.displayTitle];
}

- (NSArray*)titles {
    return [self.relatedSearchResults.results bk_map:^id (MWKSearchResult* obj) {
        return [self.title.site titleWithString:obj.displayTitle];
    }];
}

- (NSUInteger)titleCount {
    return [self.relatedSearchResults.results count];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (nullable NSString*)displayTitle {
    return [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.title.text];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath* __nonnull)indexPath {
    return NO;
}

- (NSString*)analyticsName {
    return @"Related";
}

@end

NS_ASSUME_NONNULL_END
