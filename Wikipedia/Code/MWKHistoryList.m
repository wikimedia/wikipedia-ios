#import <WMF/MWKHistoryList.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/WMF-Swift.h>

#define MAX_HISTORY_ENTRIES 100

NS_ASSUME_NONNULL_BEGIN

@interface MWKHistoryList ()

@property (readwrite, weak, nonatomic) MWKDataStore *dataStore;
@property (nonatomic, readonly) NSFetchRequest *historyListFetchRequest;

@end

@implementation MWKHistoryList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - Convienence Methods

- (NSFetchRequest *)historyListFetchRequest {
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"viewedDate != NULL"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"viewedDate" ascending:NO]];
    return request;
}

- (NSInteger)numberOfItems {
    return [self.dataStore.viewContext countForFetchRequest:self.historyListFetchRequest error:nil];
}

- (nullable WMFArticle *)mostRecentEntry {
    return [self mostRecentEntryInManagedObjectContext:self.dataStore.viewContext];
}

- (nullable WMFArticle *)mostRecentEntryInManagedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = self.historyListFetchRequest;
    request.fetchLimit = 1;
    return [[context executeFetchRequest:request error:nil] firstObject];
}

- (nullable WMFArticle *)entryForURL:(NSURL *)url {
    NSString *key = [url wmf_databaseKey];
    if (!key) {
        return nil;
    }

    WMFArticle *article = [self.dataStore fetchArticleWithKey:key];
    if (article.viewedDate) {
        return article;
    } else {
        return nil;
    }
}

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block {
    NSParameterAssert(block);
    if (!block) {
        return;
    }
    NSArray *allHistoryListItems = [self.dataStore.viewContext executeFetchRequest:self.historyListFetchRequest error:nil];
    [allHistoryListItems enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        block(obj, stop);
    }];
}

#pragma mark - Update Methods

- (void)addPagesToHistoryWithURLs:(NSArray<NSURL *> *)URLs {
    NSParameterAssert(URLs);
    if (!URLs) {
        return;
    }

    NSDate *now = [NSDate date];

    for (NSURL *URL in URLs) {
        if ([URL wmf_isNonStandardURL]) {
            continue;
        }
        if ([URL.wmf_title length] == 0) {
            continue;
        }
        WMFArticle *article = [self.dataStore fetchOrCreateArticleWithURL:URL];
        article.viewedDate = now;
        [article updateViewedDateWithoutTime];
    }

    NSError *error = nil;
    if (![self.dataStore save:&error]) {
        DDLogError(@"Error adding pages to history: %@", error);
    }
}

- (nullable WMFArticle *)addPageToHistoryWithURL:(NSURL *)URL {
    NSParameterAssert(URL);
    if (!URL) {
        return nil;
    }

    if ([URL wmf_isNonStandardURL]) {
        return nil;
    }

    if ([URL.wmf_title length] == 0) {
        return nil;
    }

    NSDate *now = [NSDate date];

    WMFArticle *article = [self.dataStore fetchOrCreateArticleWithURL:URL];

    if (!article.displayTitleHTML) {
        return article;
    }

    article.viewedDate = now;
    [article updateViewedDateWithoutTime];

    NSError *error = nil;
    if (![self.dataStore save:&error]) {
        DDLogError(@"Error adding pages to history: %@", error);
    }

    return article;
}

- (void)setFragment:(nullable NSString *)fragment scrollPosition:(double)scrollposition onPageInHistoryWithURL:(NSURL *)URL {
    if ([URL wmf_isNonStandardURL]) {
        return;
    }

    if ([URL.wmf_title length] == 0) {
        return;
    }

    WMFArticle *article = [self.dataStore fetchArticleWithURL:URL];
    article.viewedFragment = fragment;
    article.viewedScrollPosition = scrollposition;

    NSError *error = nil;
    if (![self.dataStore save:&error]) {
        DDLogError(@"Error setting fragment and scroll position: %@", error);
    }
}

- (void)setSignificantlyViewedOnPageInHistoryWithURL:(NSURL *)URL {
    if ([URL wmf_isNonStandardURL]) {
        return;
    }

    if ([URL.wmf_title length] == 0) {
        return;
    }

    WMFArticle *article = [self.dataStore fetchArticleWithURL:URL];
    article.wasSignificantlyViewed = YES;

    NSError *error = nil;
    if (![self.dataStore save:&error]) {
        DDLogError(@"Error setting significantly viewed: %@", error);
    }
}

- (void)removeEntryWithURL:(NSURL *)URL {
    if ([URL wmf_isNonStandardURL]) {
        return;
    }

    if ([URL.wmf_title length] == 0) {
        return;
    }

    WMFArticle *article = [self.dataStore fetchArticleWithURL:URL];
    article.viewedDate = nil;
    article.wasSignificantlyViewed = NO;
    [article updateViewedDateWithoutTime];

    NSError *error = nil;
    if (![self.dataStore save:&error]) {
        DDLogError(@"Error setting last viewed date: %@", error);
    }
}

- (void)removeAllEntries {
    [self enumerateItemsWithBlock:^(WMFArticle *_Nonnull entry, BOOL *_Nonnull stop) {
        entry.viewedDate = nil;
        entry.wasSignificantlyViewed = NO;
        [entry updateViewedDateWithoutTime];
    }];

    NSError *error = nil;
    if (![self.dataStore save:&error]) {
        DDLogError(@"Error removing all entries: %@", error);
    }
}

@end

NS_ASSUME_NONNULL_END
