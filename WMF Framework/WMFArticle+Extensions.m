#import <WMF/WMFArticle+Extensions.h>
#import <WMF/WMF-Swift.h>

@implementation WMFArticle (Extensions)

- (NSString *)capitalizedWikidataDescription {
    return [self.wikidataDescription wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:self.URL.wmf_language];
}

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
        return [self imageURLForWidth:240]; //hardcoded to not rely on UIScreen in a model object
    }
    return [NSURL URLWithString:thumbnailURLString];
}

- (nullable NSURL *)imageURLForWidth:(NSInteger)width {
    NSAssert(width > 0, @"Width must be > 0");
    if (width <= 0) {
        return nil;
    }
    NSString *imageURLString = self.imageURLString;
    NSNumber *imageWidth = self.imageWidth;
    if (!imageURLString || !imageWidth) {
        NSString *thumbnailURLString = self.thumbnailURLString;
        if (!thumbnailURLString) {
            return nil;
        }
        NSInteger sizePrefix = WMFParseSizePrefixFromSourceURL(thumbnailURLString);
        if (sizePrefix == NSNotFound || width >= sizePrefix) {
            return [NSURL URLWithString:thumbnailURLString];
        }
        return [NSURL URLWithString:WMFChangeImageSourceURLSizePrefix(thumbnailURLString, width)];
    }
    NSString *lowercasePathExtension = [[imageURLString pathExtension] lowercaseString];
    if (width >= [imageWidth integerValue] && ![lowercasePathExtension isEqualToString:@"svg"] && ![lowercasePathExtension isEqualToString:@"pdf"]) {
        return [NSURL URLWithString:imageURLString];
    }
    return [NSURL URLWithString:WMFChangeImageSourceURLSizePrefix(imageURLString, width)];
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
    if ([searchResult.displayTitleHTML length] > 0) {
        self.displayTitleHTML = searchResult.displayTitleHTML;
    } else if ([searchResult.displayTitle length] > 0) {
        self.displayTitleHTML = searchResult.displayTitle;
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

- (nullable WMFArticle *)fetchArticleWithWikidataID:(nullable NSString *)wikidataID {
    if (!wikidataID) {
        return nil;
    }
    WMFArticle *article = nil;
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.fetchLimit = 1;
    request.predicate = [NSPredicate predicateWithFormat:@"wikidataID == %@", wikidataID];
    article = [[self executeFetchRequest:request error:nil] firstObject];
    return article;
}

- (nullable WMFArticle *)createArticleWithKey:(nullable NSString *)key {
    WMFArticle *article = [[WMFArticle alloc] initWithEntity:[NSEntityDescription entityForName:@"WMFArticle" inManagedObjectContext:self] insertIntoManagedObjectContext:self];
    article.key = key;
    return article;
}

- (nullable WMFArticle *)fetchOrCreateArticleWithKey:(nullable NSString *)key {
    if (!key) {
        return nil;
    }
    WMFArticle *article = [self fetchArticleWithKey:key];
    if (!article) {
        article = [self createArticleWithKey:key];
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

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL updatedWithFeedPreview:(nullable WMFFeedArticlePreview *)feedPreview pageViews:(nullable NSDictionary<NSDate *, NSNumber *> *)pageViews {
    NSParameterAssert(articleURL);
    if (!articleURL) {
        return nil;
    }

    WMFArticle *preview = [self fetchOrCreateArticleWithURL:articleURL];
    if ([feedPreview.displayTitleHTML length] > 0) {
        preview.displayTitleHTML = feedPreview.displayTitleHTML;
    } else if ([feedPreview.displayTitle length] > 0) {
        preview.displayTitleHTML = feedPreview.displayTitle;
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
    if (feedPreview.imageURLString != nil) {
        preview.imageURLString = feedPreview.imageURLString;
    }
    if (feedPreview.imageWidth != nil) {
        preview.imageWidth = feedPreview.imageWidth;
    }
    if (feedPreview.imageHeight != nil) {
        preview.imageHeight = feedPreview.imageHeight;
    }
    return preview;
}

@end
