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

- (nullable WMFArticle *)itemForURL:(NSURL *)url inManagedObjectContext:(NSManagedObjectContext *)moc {
    return [self.dataStore fetchArticleForURL:url inManagedObjectContext:moc];
}

- (WMFArticle *)newOrExistingPreviewWithURL:(NSURL *)url inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSParameterAssert(url.wmf_title);
    return [self.dataStore fetchOrCreateArticleForURL:url inManagedObjectContext:moc];
}

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithSearchResult:(MWKSearchResult *)searchResult inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {

    NSParameterAssert(url);

    WMFArticle *preview = [self newOrExistingPreviewWithURL:url inManagedObjectContext:moc];
    [self updatePreview:preview withSearchResult:searchResult inManagedObjectContext:moc];
    return preview;
}

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithLocationSearchResult:(MWKLocationSearchResult *)searchResult inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {

    NSParameterAssert(url);

    WMFArticle *preview = [self newOrExistingPreviewWithURL:url inManagedObjectContext:moc];
    [self updatePreview:preview withLocationSearchResult:searchResult inManagedObjectContext:moc];

    return preview;
}

- (void)updatePreview:(WMFArticle *)preview withSearchResult:(MWKSearchResult *)searchResult inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {

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

- (void)updatePreview:(WMFArticle *)preview withLocationSearchResult:(MWKLocationSearchResult *)searchResult inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    [self updatePreview:preview withSearchResult:searchResult inManagedObjectContext:moc];
    if (searchResult.location != nil) {
        preview.location = searchResult.location;
    }
}

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithArticle:(MWKArticle *)article inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {

    NSParameterAssert(url);
    if (!url) {
        return nil;
    }

    WMFArticle *preview = [self newOrExistingPreviewWithURL:url inManagedObjectContext:moc];
    if ([article.displaytitle length] > 0) {
        preview.displayTitle = article.displaytitle;
    }
    if ([article.entityDescription length] > 0) {
        preview.wikidataDescription = article.entityDescription;
    }
    if ([article.summary length] > 0) {
        preview.snippet = article.summary;
    }

//    This whole block is commented out due to the fact that articles are requested with @"pilicense": @"any" and we can't use those thumbs in previews. Uncomment this block of code when this issue is resolved: https://phabricator.wikimedia.org/T162474
//    //The thumb from the article is almost always worse, dont use it unless we have to
//    if (preview.thumbnailURL == nil && [article bestThumbnailImageURL] != nil) {
//        NSURL *thumb = [NSURL URLWithString:[article bestThumbnailImageURL]];
//        preview.thumbnailURL = thumb;
//    }
    
    preview.isExcludedFromFeed = article.ns != 0 || url.wmf_isMainPage;
    
    [preview updateWithScalarCoordinate:article.coordinate];
    
    preview.isDownloaded = NO; //isDownloaded == NO so that any new images added to the article will be downloaded by the SavedArticlesFetcher
    
    return preview;
}

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithFeedPreview:(WMFFeedArticlePreview *)feedPreview pageViews:(nullable NSDictionary<NSDate *, NSNumber *> *)pageViews inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    NSParameterAssert(url);
    if (!url) {
        return nil;
    }

    WMFArticle *preview = [self newOrExistingPreviewWithURL:url inManagedObjectContext:moc];
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
