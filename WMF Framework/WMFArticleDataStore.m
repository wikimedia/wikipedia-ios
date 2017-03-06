#import "WMFArticleDataStore.h"
#import "MWKSearchResult.h"
#import "MWKLocationSearchResult.h"
#import "MWKArticle.h"
#import "WMFFeedArticlePreview.h"
@import CoreData;
#import "WMFArticle+Extensions.h"
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleDataStore ()

@property (nonatomic, strong) MWKDataStore *dataStore;

@end

@implementation WMFArticleDataStore

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

- (nullable WMFArticle *)itemForURL:(NSURL *)url {
    return [self.dataStore fetchArticleForURL:url];
}

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull item, BOOL *stop))block {
    [self.dataStore enumerateArticlesWithBlock:block];
}

- (WMFArticle *)newOrExistingPreviewWithURL:(NSURL *)url {
    NSParameterAssert(url.wmf_title);
    return [self.dataStore fetchOrCreateArticleForURL:url];
}

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithSearchResult:(MWKSearchResult *)searchResult {

    NSParameterAssert(url);

    WMFArticle *preview = [self newOrExistingPreviewWithURL:url];
    [self updatePreview:preview withSearchResult:searchResult];
    return preview;
}

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithLocationSearchResult:(MWKLocationSearchResult *)searchResult {

    NSParameterAssert(url);

    WMFArticle *preview = [self newOrExistingPreviewWithURL:url];
    [self updatePreview:preview withLocationSearchResult:searchResult];

    return preview;
}

- (void)updatePreview:(WMFArticle *)preview withSearchResult:(MWKSearchResult *)searchResult {

    if ([searchResult.displayTitle length] > 0) {
        preview.displayTitle = searchResult.displayTitle;
    }
    if ([searchResult.wikidataDescription length] > 0) {
        preview.wikidataDescription = searchResult.wikidataDescription;
    }
    if ([searchResult.extract length] > 0) {
        preview.snippet = searchResult.extract;
    }
    if (searchResult.thumbnailURL != nil) {
        preview.thumbnailURL = searchResult.thumbnailURL;
    }
    if (searchResult.location != nil) {
        preview.location = searchResult.location;
    }
    if (searchResult.geoDimension != nil) {
        preview.geoDimensionNumber = searchResult.geoDimension;
    }
    if (searchResult.geoType != nil) {
        preview.geoTypeNumber = searchResult.geoType;
    }
}

- (void)updatePreview:(WMFArticle *)preview withLocationSearchResult:(MWKLocationSearchResult *)searchResult {
    [self updatePreview:preview withSearchResult:searchResult];
    if (searchResult.location != nil) {
        preview.location = searchResult.location;
    }
}

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithArticle:(MWKArticle *)article {

    NSParameterAssert(url);
    if (!url) {
        return nil;
    }

    WMFArticle *preview = [self newOrExistingPreviewWithURL:url];
    if ([article.displaytitle length] > 0) {
        preview.displayTitle = article.displaytitle;
    }
    if ([article.entityDescription length] > 0) {
        preview.wikidataDescription = article.entityDescription;
    }
    if ([article.summary length] > 0) {
        preview.snippet = article.summary;
    }
    //The thumb from the article is almost always worse, dont use it unless we have to
    if (preview.thumbnailURL == nil && [article bestThumbnailImageURL] != nil) {
        NSURL *thumb = [NSURL URLWithString:[article bestThumbnailImageURL]];
        preview.thumbnailURL = thumb;
    }
    
    preview.isExcludedFromFeed = article.ns != 0;
    
    [preview updateWithScalarCoordinate:article.coordinate];
    
    return preview;
}

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithFeedPreview:(WMFFeedArticlePreview *)feedPreview pageViews:(nullable NSDictionary<NSDate *, NSNumber *> *)pageViews {
    NSParameterAssert(url);
    if (!url) {
        return nil;
    }

    WMFArticle *preview = [self newOrExistingPreviewWithURL:url];
    if ([feedPreview.displayTitle length] > 0) {
        preview.displayTitle = feedPreview.displayTitle;
    }
    if ([feedPreview.wikidataDescription length] > 0) {
        preview.wikidataDescription = feedPreview.wikidataDescription;
    }
    if ([feedPreview.snippet length] > 0) {
        preview.snippet = feedPreview.snippet;
    }
    if (feedPreview.thumbnailURL != nil) {
        preview.thumbnailURL = feedPreview.thumbnailURL;
    }
    if (pageViews != nil) {
        if (preview.pageViews == nil) {
            preview.pageViews = pageViews;
        } else {
            preview.pageViews = [preview.pageViews mtl_dictionaryByAddingEntriesFromDictionary:pageViews];
        }
    }

    return preview;
}

@end

NS_ASSUME_NONNULL_END
