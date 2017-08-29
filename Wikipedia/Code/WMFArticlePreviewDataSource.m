#import "WMFArticlePreviewDataSource.h"

// Frameworks
#import "Wikipedia-Swift.h"

// View
#import <WMF/UIView+WMFDefaultNib.h>

// Fetcher
#import <WMF/WMFArticlePreviewFetcher.h>

// Model
#import <WMF/MWKArticle.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/MWKHistoryEntry.h>
#import <WMF/MWKDataStore.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewDataSource ()

@property (nonatomic, strong) WMFArticlePreviewFetcher *titlesSearchFetcher;
@property (nonatomic, strong, readwrite, nullable) NSArray<MWKSearchResult *> *previewResults;
@property (nonatomic, strong) NSURL *siteURL;
@property (nonatomic, strong) NSArray<NSURL *> *urls;
@property (nonatomic, assign) NSUInteger resultLimit;

@property (nonatomic, strong) MWKDataStore *dataStore;

@property (nonatomic, strong) WMFTheme *theme;

@end

@implementation WMFArticlePreviewDataSource

- (NSString *)analyticsContext {
    return @"Article Disambiguation";
}

- (instancetype)initWithArticleURLs:(NSArray<NSURL *> *)articleURLs
                            siteURL:(NSURL *)siteURL
                          dataStore:(MWKDataStore *)dataStore
                            fetcher:(WMFArticlePreviewFetcher *)fetcher {
    NSParameterAssert(articleURLs);
    NSParameterAssert(fetcher);
    NSParameterAssert(dataStore);
    NSParameterAssert(siteURL);
    self = [super initWithItems:nil];
    if (self) {
        self.theme = [WMFTheme standard];
        self.dataStore = dataStore;
        self.urls = articleURLs;
        self.siteURL = siteURL;
        self.titlesSearchFetcher = fetcher;

        self.cellClass = [WMFArticleListTableViewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticleListTableViewCell *cell,
                                    MWKSearchResult *searchResult,
                                    UITableView *tableView,
                                    NSIndexPath *indexPath) {
            @strongify(self);
            NSURL *URL = [self urlForIndexPath:indexPath];
            NSParameterAssert([URL.wmf_domain isEqual:siteURL.wmf_domain]);
            cell.titleText = URL.wmf_title;
            cell.descriptionText = [searchResult.wikidataDescription wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:self.siteURL.wmf_language];
            [cell setImageURL:searchResult.thumbnailURL];
            [cell applyTheme:self.theme];
        };
    }
    return self;
}

- (MWKSavedPageList *)savedPageList {
    return self.dataStore.savedPageList;
}

- (void)setTableView:(nullable UITableView *)tableView {
    [super setTableView:tableView];
    [self.tableView registerClass:[WMFArticleListTableViewCell class] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
}

#pragma mark - Fetching

- (void)fetch {
    @weakify(self);
    [self.titlesSearchFetcher fetchArticlePreviewResultsForArticleURLs:self.urls
                                                               siteURL:self.siteURL
                                                            completion:^(NSArray<MWKSearchResult *> *_Nonnull searchResults) {
                                                                @strongify(self);
                                                                if (!self) {
                                                                    return;
                                                                }
                                                                self.previewResults = searchResults;
                                                                [self updateItems:searchResults];
                                                            }
                                                               failure:^(NSError *_Nonnull error){
                                                               }];
}

#pragma mark - WMFArticleListDataSource

- (MWKSearchResult *)searchResultForIndexPath:(NSIndexPath *)indexPath {
    MWKSearchResult *result = self.previewResults[indexPath.row];
    return result;
}

- (NSURL *)urlForIndexPath:(NSIndexPath *)indexPath {
    return [self.siteURL wmf_URLWithTitle:[self searchResultForIndexPath:indexPath].displayTitle];
}

- (NSUInteger)titleCount {
    return [self.previewResults count];
}

- (nullable NSString *)displayTitle {
    return WMFLocalizedStringWithDefaultValue(@"page-similar-titles", nil, nil, @"Similar pages", @"Label for button that shows a list of similar titles (disambiguation) for the current page");
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    [self.tableView reloadData];
}

@end

NS_ASSUME_NONNULL_END
