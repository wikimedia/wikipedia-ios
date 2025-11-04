#import <WMF/MWKSavedPageList.h>
#import <WMF/WMF-Swift.h>

@interface MWKSavedPageList () <NSFetchedResultsControllerDelegate>

@property (readwrite, weak, nonatomic) MWKDataStore *dataStore;

@property (nonatomic, readonly) NSFetchRequest *savedPageListFetchRequest;

@end

@implementation MWKSavedPageList

#pragma mark - Setup

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - Convienence Methods

- (NSFetchRequest *)savedPageListFetchRequest {
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"savedDate != NULL"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"savedDate" ascending:NO]];
    return request;
}

- (NSFetchRequest *)savedPageListFetchRequestForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate filterNilDisplayTitles:(BOOL)filterNilDisplayTitles {
    NSFetchRequest *request = [WMFArticle fetchRequest];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"savedDate >= %@ AND savedDate <= %@", startDate, endDate];

    if (filterNilDisplayTitles) {
        predicate = [NSPredicate predicateWithFormat:@"savedDate >= %@ AND savedDate <= %@ AND displayTitle != nil", startDate, endDate];
    }

    request.predicate = predicate;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"savedDate" ascending:NO]];
    return request;
}

- (NSInteger)numberOfItems {
    return [self.dataStore.viewContext countForFetchRequest:self.savedPageListFetchRequest error:nil];
}

- (nullable WMFArticle *)mostRecentEntry {
    NSFetchRequest *request = self.savedPageListFetchRequest;
    request.fetchLimit = 1;
    return [[self.dataStore.viewContext executeFetchRequest:request error:nil] firstObject];
}

- (nullable WMFArticle *)entryForURL:(NSURL *)url {
    NSString *key = url.wmf_databaseKey;
    if (!key) {
        return nil;
    }
    WMFArticle *article = [self.dataStore fetchArticleWithKey:key variant:url.wmf_languageVariantCode];
    if (article.savedDate) {
        return article;
    } else {
        return nil;
    }
}

- (nullable WMFArticle *)articleToUnsaveForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    WMFArticle *article = [self.dataStore fetchArticleWithKey:key];
    if (article.savedDate) {
        return article;
    } else {
        return nil;
    }
}

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block {
    if (!block) {
        return;
    }

    NSFetchRequest *request = self.savedPageListFetchRequest;
    NSArray<WMFArticle *> *allEntries = [self.dataStore.viewContext executeFetchRequest:request error:nil];
    [allEntries enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        block(obj, stop);
    }];
}

- (BOOL)isAnyVariantSaved:(NSURL *)url {
    if ([url.wmf_title length] == 0) {
        return NO;
    }
    WMFArticle *article = [self.dataStore fetchArticleWithURL:url];
    return article.isAnyVariantSaved;
}

#pragma mark - Update Methods

/** These methods accept a 'fully qualified' article specification consisting of the database key and the language variant.
 *  When adding to the list, that specific variant is added to the list.
 *  When removed from the list, *any* article that matches that database key is removed from the list.
 *  That logic is handled in the reading lists controller, and these methods just pass along the 'fully qualified' articles or URLs.
 *  However, the methods in this class do need to take into account whether any variants are saved to determine the correct toggle behavior.
 */

- (BOOL)toggleSavedPageForURL:(NSURL *)url {
    if ([self isAnyVariantSaved:url]) {
        [self removeEntryWithURL:url];
        return NO;
    } else {
        [self addSavedPageWithURL:url];
        return YES;
    }
}

- (BOOL)toggleSavedPageForKey:(NSString *)key variant:(nullable NSString *)variant {
    if (!key) {
        return NO;
    }
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    if (!moc) {
        return NO;
    }
    WMFArticle *article = [self.dataStore fetchArticleWithKey:key variant:variant];
    if (article.isAnyVariantSaved) {
        [self.dataStore.readingListsController userUnsave:article];
    } else {
        [self.dataStore.readingListsController userSave:article];
    }
    return article.savedDate != nil;
}

- (void)addSavedPageWithURL:(NSURL *)url {
    WMFArticle *article = [self.dataStore fetchOrCreateArticleWithURL:url];
    [self.dataStore.readingListsController userSave:article];
}

- (void)removeEntryWithURL:(NSURL *)url {
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    if (!moc) {
        return;
    }
    WMFArticle *article = [self.dataStore fetchArticleWithURL:url];
    if (!article) {
        return;
    }
    [self.dataStore.readingListsController userUnsave:article];
}

- (NSInteger)savedArticleCountFor:(NSDate *)startDate endDate:(NSDate *)endDate {
    return [self.dataStore.viewContext countForFetchRequest:[self savedPageListFetchRequestForStartDate:startDate endDate:endDate filterNilDisplayTitles:NO] error:nil];
}

- (NSArray<NSString *> *)randomSavedArticleTitlesFor:(NSDate *)startDate endDate:(NSDate *)endDate {
    NSFetchRequest *fetchRequest = [self savedPageListFetchRequestForStartDate:startDate endDate:endDate filterNilDisplayTitles:YES];

    NSError *error = nil;
    NSArray<WMFArticle *> *allArticles = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        NSLog(@"Error fetching articles: %@", error);
        return @[];
    }

    NSUInteger count = MIN(allArticles.count, 3);
    if (count == 0) {
        return @[];
    }

    NSMutableArray<NSString *> *randomArticles = [NSMutableArray arrayWithCapacity:count];
    NSMutableArray<WMFArticle *> *mutableArticles = [allArticles mutableCopy];

    for (NSUInteger i = 0; i < count; i++) {
        NSUInteger randomIndex = arc4random_uniform((uint32_t)mutableArticles.count);
        if (mutableArticles[randomIndex].displayTitle != nil) {
            [randomArticles addObject:mutableArticles[randomIndex].displayTitle];
            [mutableArticles removeObjectAtIndex:randomIndex]; // so we do not repeat articles
        } else {
            continue;
        }
    }

    return [randomArticles copy];
}

- (NSArray<NSString *> *)randomSavedArticleImagesFor:(NSDate *)startDate endDate:(NSDate *)endDate {
    NSFetchRequest *fetchRequest = [self savedPageListFetchRequestForStartDate:startDate endDate:endDate filterNilDisplayTitles:YES];

    NSError *error = nil;
    NSArray<WMFArticle *> *allArticles = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        NSLog(@"Error fetching articles: %@", error);
        return @[];
    }

    if (allArticles.count == 0) {
        return @[];
    }

    NSMutableArray<NSString *> *randomArticleImages = [NSMutableArray arrayWithCapacity:allArticles.count];
    NSMutableArray<WMFArticle *> *mutableArticles = [allArticles mutableCopy];

    for (NSUInteger i = 0; i < allArticles.count; i++) {
        if (mutableArticles[i].thumbnailURLString != nil) {
            [randomArticleImages addObject:mutableArticles[i].thumbnailURLString];
        } else {
            continue;
        }
    }

    return [randomArticleImages copy];
}

- (nullable NSDate *)lastSavedArticleDate {
    NSFetchRequest *fetchRequest = [self savedPageListFetchRequest];
    fetchRequest.fetchLimit = 1;
    NSError *error = nil;
    NSArray<WMFArticle *> *articles = [self.dataStore.viewContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        NSLog(@"Error fetching articles: %@", error);
        return nil;
    }

    if (!articles) {
        return nil;
    }

    if (articles.count == 0) {
        return nil;
    }

    NSDate *savedDate = articles[0].savedDate;

    if (!savedDate) {
        return nil;
    }

    return savedDate;
}

@end
