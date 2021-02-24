#import <WMF/WMFArticle+Extensions.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMF-Swift.h>

@interface NSManagedObjectContext (WMFArticle_Private)
- (NSUInteger)countOfSavedArticleVariantsWithKey:(nullable NSString *)key error:(NSError **)error;
- (nullable WMFArticle *)savedArticleVariantWithKey:(nullable NSString *)key error:(NSError **)error;
@end

@implementation WMFArticle (Extensions)

- (NSString *)capitalizedWikidataDescription {
    return [self.wikidataDescription wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:self.URL.wmf_language];
}

- (nullable NSURL *)URL {
    NSString *key = self.key;
    if (!key) {
        return nil;
    }
    NSURL *value = [NSURL URLWithString:key];
    value.wmf_languageVariantCode = self.variant;
    return value;
}

- (nullable WMFInMemoryURLKey *)inMemoryKey {
    return self.URL.wmf_inMemoryKey;
}

- (BOOL)isAnyVariantSaved {
    NSUInteger savedCount = [self.managedObjectContext countOfSavedArticleVariantsWithKey:self.key error:nil];
    NSAssert(savedCount < 2, @"More than one article variant marked as saved for key '%@'", self.key);
    return savedCount > 0;
}

- (nullable WMFArticle *)savedVariant {
    // If the article has a savedDate, it is the saved variant
    if (self.savedDate != nil) {
        return self;
    // If the article does not have a variant, no further checking is needed. Return nil.
    } else if (!self.variant) {
        return nil;
    } else {
        return [self.managedObjectContext savedArticleVariantWithKey:self.key error:nil];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations" // this is the only section of code where the "deprecated" but not really deprecated displayTitleHTMLString should be used

- (void)setDisplayTitleHTML:(NSString *)displayTitleHTML {
    self.displayTitleHTMLString = displayTitleHTML;
    self.displayTitle = displayTitleHTML.wmf_stringByRemovingHTML;
}

- (NSString *)displayTitleHTML {
    return self.displayTitleHTMLString ?: self.displayTitle ?: self.URL.wmf_title ?: @"";
}

#pragma clang diagnostic pop

- (nullable NSURL *)thumbnailURL {
    NSString *thumbnailURLString = self.thumbnailURLString;
    if (!thumbnailURLString) {
        return [self imageURLForWidth:240]; //hardcoded to not rely on UIScreen in a model object
    }
    return [NSURL URLWithString:thumbnailURLString];
}

+ (nullable NSURL *)imageURLForTargetImageWidth:(NSInteger)width fromImageSource:(NSString *)imageSource withOriginalWidth:(NSInteger)originalWidth {
    NSAssert(width > 0, @"Width must be > 0");
    if (width <= 0) {
       return nil;
    }
    NSString *lowercasePathExtension = [[imageSource pathExtension] lowercaseString];
    if (width >= originalWidth && ![lowercasePathExtension isEqualToString:@"svg"] && ![lowercasePathExtension isEqualToString:@"pdf"]) {
       return [NSURL URLWithString:imageSource];
    }
    return [NSURL URLWithString:WMFChangeImageSourceURLSizePrefix(imageSource, width)];
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
    return [WMFArticle imageURLForTargetImageWidth:width fromImageSource:imageURLString withOriginalWidth:[imageWidth integerValue]];
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

#pragma mark - NSManagedObjectContext Extensions

@implementation NSManagedObjectContext (WMFArticle)

- (nullable WMFArticle *)fetchArticleWithURL:(nullable NSURL *)articleURL {
    return [self fetchArticleWithKey:articleURL.wmf_databaseKey variant:articleURL.wmf_languageVariantCode];
}

- (nullable NSArray<WMFArticle *> *)fetchArticlesWithURL:(nullable NSURL *)url error:(NSError **)error {
    return [self fetchArticlesWithKey:url.wmf_databaseKey variant:url.wmf_languageVariantCode error:error];
}

- (nullable NSArray<WMFArticle *> *)fetchArticlesWithKey:(nullable NSString *)key variant:(nullable NSString *)variant error:(NSError **)error {
    if (!key) {
        return @[];
    }
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"key == %@ && variant == %@", key, variant];
    return [self executeFetchRequest:request error:error];
}

- (nullable NSArray<WMFArticle *> *)fetchArticlesWithInMemoryURLKeys:(NSArray<WMFInMemoryURLKey *> *)urlKeys error:(NSError **)error {
    if (urlKeys.count == 0) {
        return @[];
    }
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [self articlePredicateForInMemoryURLKeys:urlKeys];
    return [self executeFetchRequest:request error:error];
}

- (NSPredicate *)articlePredicateForInMemoryURLKeys:(NSArray<WMFInMemoryURLKey *> *)urlKeys {
    NSMutableArray<NSPredicate *> *subpredicates = [[NSMutableArray alloc] init];
    for (WMFInMemoryURLKey *urlKey in urlKeys) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key == %@ && variant == %@", urlKey.databaseKey, urlKey.languageVariantCode];
        [subpredicates addObject:predicate];
    }
    return [NSCompoundPredicate orPredicateWithSubpredicates:subpredicates];
}

- (nullable WMFArticle *)fetchArticleWithKey:(nullable NSString *)key variant:(nullable NSString *)variant {
    if (!key) {
        return nil;
    }
    WMFArticle *article = nil;
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.fetchLimit = 1;
    request.predicate = [NSPredicate predicateWithFormat:@"key == %@ && variant == %@", key, variant];
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

- (nullable WMFArticle *)createArticleWithURL:(nullable NSURL *)url {
    return [self createArticleWithKey:url.wmf_databaseKey variant:url.wmf_languageVariantCode];
}

- (nullable WMFArticle *)createArticleWithKey:(nullable NSString *)key variant:(nullable NSString *)variant {
    WMFArticle *article = [[WMFArticle alloc] initWithContext:self];
    article.key = key;
    article.variant = variant;
    return article;
}

- (nullable WMFArticle *)fetchOrCreateArticleWithKey:(nullable NSString *)key variant:(nullable NSString *)variant {
    if (!key) {
        return nil;
    }
    WMFArticle *article = [self fetchArticleWithKey:key variant:variant];
    if (!article) {
        article = [self createArticleWithKey:key variant:variant];
    }
    return article;
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL {
    return [self fetchOrCreateArticleWithKey:articleURL.wmf_databaseKey variant:articleURL.wmf_languageVariantCode];
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


@implementation NSManagedObjectContext (WMFArticle_Private)

- (NSUInteger)countOfSavedArticleVariantsWithKey:(nullable NSString *)key error:(NSError **)error {
    if (!key) {
        return 0;
    }
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"key == %@ && savedDate != NULL", key];
    NSUInteger count =  [self countForFetchRequest:request error:error];
    return count == NSNotFound ? 0 : count;
}

- (nullable WMFArticle *)savedArticleVariantWithKey:(nullable NSString *)key error:(NSError **)error {
    if (!key) {
        return nil;
    }
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"key == %@ && savedDate != NULL", key];
    return (WMFArticle *)[[self executeFetchRequest:request error:error] firstObject];
}

@end
