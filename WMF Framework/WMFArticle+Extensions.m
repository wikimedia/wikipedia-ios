#import "WMFArticle+Extensions.h"
#import <WMF/WMF-Swift.h>

@implementation WMFArticle (Extensions)

- (nullable NSURL *)URL {
    NSString *key = self.key;
    if (!key) {
        return nil;
    }
    return [NSURL URLWithString:key];
}

- (nullable NSURL *)thumbnailURL {
    NSString *thumbnailURLString = self.thumbnailURLString;
    if (!thumbnailURLString) {
        return nil;
    }
    return [NSURL URLWithString:thumbnailURLString];
}

- (void)setThumbnailURL:(NSURL *)thumbnailURL {
    self.thumbnailURLString = thumbnailURL.absoluteString;
}

- (NSArray<NSNumber *> *)pageViewsSortedByDate {
    return self.pageViews.wmf_pageViewsSortedByDate;
}

- (void)updateViewedDateWithoutTime {
    NSDate *viewedDate = self.viewedDate;
    if (viewedDate) {
        NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:viewedDate];
        self.viewedDateWithoutTime = [calendar dateFromComponents:components];
    } else {
        self.viewedDateWithoutTime = nil;
    }
}

- (void)updateWithSearchResult:(nullable MWKSearchResult *)searchResult {
    if ([searchResult.displayTitle length] > 0) {
        self.displayTitle = searchResult.displayTitle;
    }
    if ([searchResult.wikidataDescription length] > 0) {
        self.wikidataDescription = searchResult.wikidataDescription;
    }
    if ([searchResult.extract length] > 0) {
        self.snippet = searchResult.extract;
    }
    if (searchResult.thumbnailURL != nil) {
        self.thumbnailURL = searchResult.thumbnailURL;
    }
    if (searchResult.location != nil) {
        self.location = searchResult.location;
    }
    if (searchResult.geoDimension != nil) {
        self.geoDimensionNumber = searchResult.geoDimension;
    }
    if (searchResult.geoType != nil) {
        self.geoTypeNumber = searchResult.geoType;
    }
}

- (void)updateWithMWKArticle:(MWKArticle *)article {
    if ([article.displaytitle length] > 0) {
        self.displayTitle = article.displaytitle;
    }
    if ([article.entityDescription length] > 0) {
        self.wikidataDescription = article.entityDescription;
    }
    if ([article.summary length] > 0) {
        self.snippet = article.summary;
    }
    
    //    This whole block is commented out due to the fact that articles are requested with @"pilicense": @"any" and we can't use those thumbs in previews. Uncomment this block of code when this issue is resolved: https://phabricator.wikimedia.org/T162474
    //    //The thumb from the article is almost always worse, dont use it unless we have to
    //    if (preview.thumbnailURL == nil && [article bestThumbnailImageURL] != nil) {
    //        NSURL *thumb = [NSURL URLWithString:[article bestThumbnailImageURL]];
    //        preview.thumbnailURL = thumb;
    //    }
    
    self.isExcludedFromFeed = article.ns != 0 || self.URL.wmf_isMainPage;
    
    [self updateWithScalarCoordinate:article.coordinate];
    
    self.isDownloaded = NO; //isDownloaded == NO so that any new images added to the article will be downloaded by the SavedArticlesFetcher
}

@end

@implementation NSManagedObjectContext (WMFArticle)

- (nullable WMFArticle *)fetchArticleWithURL:(nullable NSURL *)articleURL {
    return [self fetchArticleWithKey:[articleURL wmf_articleDatabaseKey]];
}

- (nullable WMFArticle *)fetchArticleWithKey:(nullable NSString *)key {
    if (!key) {
        return nil;
    }
    WMFArticle *article = nil;
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.fetchLimit = 1;
    request.predicate = [NSPredicate predicateWithFormat:@"key == %@", key];
    article = [[self executeFetchRequest:request error:nil] firstObject];
    return article;
}

- (nullable WMFArticle *)fetchOrCreateArticleWithKey:(nullable NSString *)key {
    if (!key) {
        return nil;
    }
    WMFArticle *article = [self fetchArticleWithKey:key];
    if (!article) {
        article = [[WMFArticle alloc] initWithEntity:[NSEntityDescription entityForName:@"WMFArticle" inManagedObjectContext:self] insertIntoManagedObjectContext:self];
        article.key = key;
    }
    return article;
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL {
    return [self fetchOrCreateArticleWithKey:[articleURL wmf_articleDatabaseKey]];
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL updatedWithSearchResult:(nullable MWKSearchResult *)searchResult {
    
    NSParameterAssert(articleURL);
    WMFArticle *article = [self fetchOrCreateArticleWithURL:articleURL];
    [article updateWithSearchResult:searchResult];
    return article;
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL updatedWithMWKArticle:(nullable MWKArticle *)article {
    NSParameterAssert(articleURL);
    if (!articleURL) {
        return nil;
    }
    
    WMFArticle *preview = [self fetchOrCreateArticleWithURL:articleURL];
    [preview updateWithMWKArticle:article];
    return preview;
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL updatedWithFeedPreview:(nullable WMFFeedArticlePreview *)feedPreview pageViews:(nullable NSDictionary<NSDate *, NSNumber *> *)pageViews {
    NSParameterAssert(articleURL);
    if (!articleURL) {
        return nil;
    }
    
    WMFArticle *preview = [self fetchOrCreateArticleWithURL:articleURL];
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
