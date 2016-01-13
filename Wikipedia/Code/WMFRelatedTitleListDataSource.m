
#import "WMFRelatedTitleListDataSource.h"

// Frameworks
#import "Wikipedia-Swift.h"

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


NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedTitleListDataSource ()

@property (nonatomic, copy, readwrite) MWKTitle* title;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) WMFRelatedSearchFetcher* relatedSearchFetcher;
@property (nonatomic, strong, readwrite, nullable) WMFRelatedSearchResults* relatedSearchResults;

@property (nonatomic, assign) NSUInteger resultLimit;

@end

@implementation WMFRelatedTitleListDataSource

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                  resultLimit:(NSUInteger)resultLimit {
    return [self initWithTitle:title
                     dataStore:dataStore
                   resultLimit:resultLimit
                       fetcher:[[WMFRelatedSearchFetcher alloc] init]];
}

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                  resultLimit:(NSUInteger)resultLimit
                      fetcher:(WMFRelatedSearchFetcher*)fetcher {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    NSParameterAssert(fetcher);
    self = [super initWithItems:nil];
    if (self) {
        self.title                = title;
        self.dataStore            = dataStore;
        self.relatedSearchFetcher = fetcher;
        self.resultLimit          = resultLimit;
    }
    return self;
}

- (MWKSavedPageList*)savedPageList {
    return self.dataStore.userDataStore.savedPageList;
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

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath* __nonnull)indexPath {
    return NO;
}

@end

NS_ASSUME_NONNULL_END
