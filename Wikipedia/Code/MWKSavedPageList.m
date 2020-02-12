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

- (NSInteger)numberOfItems {
    return [self.dataStore.viewContext countForFetchRequest:self.savedPageListFetchRequest error:nil];
}

- (nullable WMFArticle *)mostRecentEntry {
    NSFetchRequest *request = self.savedPageListFetchRequest;
    request.fetchLimit = 1;
    return [[self.dataStore.viewContext executeFetchRequest:request error:nil] firstObject];
}

- (nullable WMFArticle *)entryForURL:(NSURL *)url {
    NSString *key = [url wmf_databaseKey];
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

- (nullable WMFArticle *)entryForKey:(NSString *)key {
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

- (BOOL)isSaved:(NSURL *)url {
    if ([url.wmf_title length] == 0) {
        return NO;
    }
    return [self entryForURL:url] != nil;
}

#pragma mark - Update Methods

- (BOOL)toggleSavedPageForURL:(NSURL *)url {
    if ([self isSaved:url]) {
        [self removeEntryWithURL:url];
        return NO;
    } else {
        [self addSavedPageWithURL:url];
        return YES;
    }
}

- (BOOL)toggleSavedPageForKey:(NSString *)key {
    if (!key) {
        return NO;
    }
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    if (!moc) {
        return NO;
    }
    WMFArticle *article = [self.dataStore fetchArticleWithKey:key];
    if (article.savedDate == nil) {
        [self.dataStore.readingListsController userSave:article];
    } else {
        [self.dataStore.readingListsController userUnsave:article];
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

- (void)removeEntriesWithURLs:(NSArray<NSURL *> *)urls {
    [self.dataStore.readingListsController removeArticlesWithURLsFromDefaultReadingList:urls];
}

@end
