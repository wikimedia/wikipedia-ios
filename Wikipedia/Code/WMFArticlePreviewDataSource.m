//  Created by Monte Hurd on 12/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.

#import "WMFArticlePreviewDataSource.h"

// Frameworks
#import "Wikipedia-Swift.h"

// View
#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"

// Fetcher
#import "WMFArticlePreviewFetcher.h"

// Model
#import "MWKTitle.h"
#import "MWKArticle.h"
#import "MWKSearchResult.h"
#import "MWKHistoryEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewDataSource ()

@property (nonatomic, strong) WMFArticlePreviewFetcher* titlesSearchFetcher;
@property (nonatomic, strong, readwrite, nullable) NSArray<MWKSearchResult*>* previewResults;
@property (nonatomic, strong) MWKSite* site;
@property (nonatomic, strong) NSArray<MWKTitle*>* titles;
@property (nonatomic, assign) NSUInteger resultLimit;

@end

@implementation WMFArticlePreviewDataSource

- (NSString*)analyticsName {
    return @"Article Disambiguation";
}

- (instancetype)initWithTitles:(NSArray<MWKTitle*>*)titles
                          site:(MWKSite*)site
                       fetcher:(WMFArticlePreviewFetcher*)fetcher {
    NSParameterAssert(titles);
    NSParameterAssert(fetcher);
    self = [super initWithItems:nil];
    if (self) {
        self.titles = titles;
        self.site                = site;
        self.titlesSearchFetcher = fetcher;

        self.cellClass = [WMFArticlePreviewTableViewCell class];
        
        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticlePreviewTableViewCell* cell,
                                    MWKSearchResult* searchResult,
                                    UITableView* tableView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKTitle* title = [self titleForIndexPath:indexPath];
            NSParameterAssert([title.site isEqualToSite:site]);
            cell.titleText       = title.text;
            cell.descriptionText = searchResult.wikidataDescription;
            cell.snippetText     = searchResult.extract;
            [cell setImageURL:searchResult.thumbnailURL];
            [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
            
        };
    }
    return self;
}

- (void)setTableView:(nullable UITableView*)tableView {
    [super setTableView:tableView];
    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
}

#pragma mark - Fetching

- (void)fetch {
    @weakify(self);
    [self.titlesSearchFetcher fetchArticlePreviewResultsForTitles:self.titles site:self.site]
    .then(^(NSArray<MWKSearchResult*>* searchResults) {
        @strongify(self);
        if (!self) {
            return;
        }
        self.previewResults = searchResults;
        [self updateItems:searchResults];
    });
}

#pragma mark - WMFArticleListDataSource

- (MWKSearchResult*)searchResultForIndexPath:(NSIndexPath*)indexPath {
    MWKSearchResult* result = self.previewResults[indexPath.row];
    return result;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKSearchResult* result = [self searchResultForIndexPath:indexPath];
    return [self.site titleWithString:result.displayTitle];
}

- (NSUInteger)titleCount {
    return [self.previewResults count];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodLink;
}

- (nullable NSString*)displayTitle {
    return MWLocalizedString(@"page-similar-titles", nil);
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath* __nonnull)indexPath {
    return NO;
}

@end

NS_ASSUME_NONNULL_END
