#import "WMFArticlePreviewDataStore.h"
#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"

#import "MWKSearchResult.h"
#import "MWKLocationSearchResult.h"
#import "MWKArticle.h"
#import "WMFFeedArticlePreview.h"
@import CoreData;
#import "WMFArticlePreview+Extensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewDataStore ()

@property (nonatomic, strong) MWKDataStore *dataStore;

@end

@implementation WMFArticlePreviewDataStore

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

- (nullable WMFArticlePreview *)itemForURL:(NSURL *)url {
    return [self.dataStore fetchArticlePreviewForURL:url];
}

- (void)enumerateItemsWithBlock:(void (^)(WMFArticlePreview *_Nonnull item, BOOL *stop))block {
    if (!block) {
        return;
    }
    
    NSFetchRequest *request = [WMFArticlePreview fetchRequest];
    NSArray<WMFArticlePreview *> *allArticlePreviews = [self.dataStore.viewContext executeFetchRequest:request error:nil];
    [allArticlePreviews enumerateObjectsUsingBlock:^(WMFArticlePreview * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, stop);
    }];
}

- (WMFArticlePreview *)newOrExistingPreviewWithURL:(NSURL *)url {
    NSParameterAssert(url.wmf_title);
    return [self.dataStore fetchOrCreateArticlePreviewForURL:url];
}

- (void)savePreview:(WMFArticlePreview *)preview {
    [self.dataStore save:nil];
}

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithSearchResult:(MWKSearchResult *)searchResult {

    NSParameterAssert(url);

    WMFArticlePreview *preview = [self newOrExistingPreviewWithURL:url];
    [self updatePreview:preview withSearchResult:searchResult];
    [self savePreview:preview];
    return preview;
}

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithLocationSearchResult:(MWKLocationSearchResult *)searchResult {

    NSParameterAssert(url);

    WMFArticlePreview *preview = [self newOrExistingPreviewWithURL:url];
    [self updatePreview:preview withLocationSearchResult:searchResult];
    [self savePreview:preview];
    return preview;
}

- (void)updatePreview:(WMFArticlePreview *)preview withSearchResult:(MWKSearchResult *)searchResult {

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
}

- (void)updatePreview:(WMFArticlePreview *)preview withLocationSearchResult:(MWKLocationSearchResult *)searchResult {
    [self updatePreview:preview withSearchResult:searchResult];
    if (searchResult.location != nil) {
        preview.location = searchResult.location;
    }
}

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithArticle:(MWKArticle *)article {

    NSParameterAssert(url);
    if (!url) {
        return nil;
    }

    WMFArticlePreview *preview = [self newOrExistingPreviewWithURL:url];
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
    [self savePreview:preview];
    return preview;
}

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithFeedPreview:(WMFFeedArticlePreview *)feedPreview pageViews:(nullable NSDictionary<NSDate *, NSNumber *> *)pageViews {
    NSParameterAssert(url);
    if (!url) {
        return nil;
    }

    WMFArticlePreview *preview = [self newOrExistingPreviewWithURL:url];
    if ([feedPreview.displayTitle length] > 0) {
        preview.displayTitle = feedPreview.displayTitle;
    }
    if ([feedPreview.wikidataDescription length] > 0) {
        preview.wikidataDescription = feedPreview.wikidataDescription;
    }
    if ([feedPreview.snippet length] > 0) {
        preview.wikidataDescription = feedPreview.wikidataDescription;
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

    [self savePreview:preview];
    return preview;
}

@end

NS_ASSUME_NONNULL_END
