#import <WMF/WMF-Swift.h>
#include <notify.h>
#import <sqlite3.h>
#import "WMFArticlePreview.h"
#import "WMFAnnouncement.h"

@import CoreData;

// Emitted when article state changes. Can be used for things such as being notified when article 'saved' state changes.
NSString *const WMFArticleUpdatedNotification = @"WMFArticleUpdatedNotification";

NSString *const MWKDataStoreValidImageSitePrefix = @"//upload.wikimedia.org/";

NSString *MWKCreateImageURLWithPath(NSString *path) {
    return [MWKDataStoreValidImageSitePrefix stringByAppendingString:path];
}

static NSString *const MWKImageInfoFilename = @"ImageInfo.plist";

@interface MWKDataStore ()

@property (readwrite, strong, nonatomic) MWKHistoryList *historyList;
@property (readwrite, strong, nonatomic) MWKSavedPageList *savedPageList;
@property (readwrite, strong, nonatomic) MWKRecentSearchList *recentSearchList;
@property (readwrite, strong, nonatomic) ArticleLocationController *articleLocationController;

@property (nonatomic, strong) WMFExploreFeedContentController *feedContentController;

@property (readwrite, copy, nonatomic) NSString *basePath;
@property (readwrite, strong, nonatomic) NSCache *articleCache;
@property (readwrite, strong, nonatomic) NSCache *articlePreviewCache;

@property (readwrite, nonatomic, strong) dispatch_queue_t cacheRemovalQueue;
@property (readwrite, nonatomic, getter=isCacheRemovalActive) BOOL cacheRemovalActive;
@property (readwrite, strong, nullable) dispatch_block_t cacheRemovalCompletion;
@property (readwrite, nonatomic, getter=wasSitesFolderMissing) BOOL sitesFolderMissing;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSOperation *> *articleSaveOperations;
@property (nonatomic, strong) NSOperationQueue *articleSaveQueue;

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *viewContext;
@property (nonatomic, strong) NSManagedObjectContext *feedImportContext;

@property (nonatomic, strong) NSString *crossProcessNotificationChannelName;
@property (nonatomic) int crossProcessNotificationToken;

@property (nonatomic, strong) NSURL *containerURL;

@end

@implementation MWKDataStore

- (NSOperationQueue *)articleSaveQueue {
    if (!_articleSaveQueue) {
        _articleSaveQueue = [NSOperationQueue new];
        _articleSaveQueue.qualityOfService = NSQualityOfServiceBackground;
        _articleSaveQueue.maxConcurrentOperationCount = 1;
    }
    return _articleSaveQueue;
}

- (NSMutableDictionary<NSString *, NSOperation *> *)articleSaveOperations {
    if (!_articleSaveOperations) {
        _articleSaveOperations = [NSMutableDictionary new];
    }
    return _articleSaveOperations;
}

- (void)asynchronouslyCacheArticle:(MWKArticle *)article toDisk:(BOOL)toDisk {
    [self asynchronouslyCacheArticle:article toDisk:toDisk completion:nil];
}

- (void)asynchronouslyCacheArticle:(MWKArticle *)article toDisk:(BOOL)toDisk completion:(nullable dispatch_block_t)completion {
    [self addArticleToMemoryCache:article];
    if (!toDisk) {
        if (completion) {
            completion();
        }
        return;
    }
    NSOperationQueue *queue = [self articleSaveQueue];
    NSMutableDictionary *operations = [self articleSaveOperations];
    @synchronized(queue) {
        NSString *key = article.url.wmf_articleDatabaseKey;
        if (!key) {
            return;
        }

        NSOperation *op = operations[key];
        if (op) {
            [op cancel];
            [operations removeObjectForKey:key];
        }

        op = [NSBlockOperation blockOperationWithBlock:^{
            [article save];
            @synchronized(queue) {
                [operations removeObjectForKey:key];
            }
        }];
        op.completionBlock = completion;

        if (!op) {
            return;
        }

        operations[key] = op;

        [queue addOperation:op];
    }
}

- (void)cancelAsynchronousCacheForArticle:(MWKArticle *)article {
    NSOperationQueue *queue = [self articleSaveQueue];
    NSMutableDictionary *operations = [self articleSaveOperations];
    @synchronized(queue) {
        NSString *key = article.url.wmf_articleDatabaseKey;
        NSOperation *op = operations[key];
        [op cancel];
        [operations removeObjectForKey:key];
    }
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [self initWithContainerURL:[[NSFileManager defaultManager] wmf_containerURL]];
    return self;
}

static uint64_t bundleHash() {
    static dispatch_once_t onceToken;
    static uint64_t bundleHash;
    dispatch_once(&onceToken, ^{
        bundleHash = (uint64_t)[[[NSBundle mainBundle] bundleIdentifier] hash];
    });
    return bundleHash;
}

- (instancetype)initWithContainerURL:(NSURL *)containerURL {
    self = [super init];
    if (self) {
        self.containerURL = containerURL;
        self.basePath = [self.containerURL URLByAppendingPathComponent:@"Data" isDirectory:YES].path;
        BOOL sitesWasADirectory = false;
        BOOL sitesExisted = [[NSFileManager defaultManager] fileExistsAtPath:[self pathForSites] isDirectory:&sitesWasADirectory];
        self.sitesFolderMissing = !sitesExisted || !sitesWasADirectory;
        [self setupLegacyDataStore];
        NSDictionary *infoDictionary = [self loadSharedInfoDictionaryWithContainerURL:containerURL];
        self.crossProcessNotificationChannelName = infoDictionary[@"CrossProcessNotificiationChannelName"];
        [self setupCrossProcessCoreDataNotifier];
        [self setupCoreDataStackWithContainerURL:containerURL];
        [self setupHistoryAndSavedPageLists];
        self.feedContentController = [[WMFExploreFeedContentController alloc] init];
        self.feedContentController.dataStore = self;
        self.feedContentController.siteURL = [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarningWithNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        self.articleLocationController = [ArticleLocationController new];
    }
    return self;
}

- (NSDictionary *)loadSharedInfoDictionaryWithContainerURL:(NSURL *)containerURL {
    NSURL *infoDictionaryURL = [containerURL URLByAppendingPathComponent:@"Wikipedia.info" isDirectory:NO];
    NSData *infoDictionaryData = [NSData dataWithContentsOfURL:infoDictionaryURL];
    NSDictionary *infoDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:infoDictionaryData];
    if (!infoDictionary[@"CrossProcessNotificiationChannelName"]) {
        NSString *channelName = [NSString stringWithFormat:@"org.wikimedia.wikipedia.cd-cpn-%@", [NSUUID new].UUIDString].lowercaseString;
        infoDictionary = @{ @"CrossProcessNotificiationChannelName": channelName };
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:infoDictionary];
        [data writeToURL:infoDictionaryURL atomically:YES];
    }
    return infoDictionary;
}

- (void)setupCrossProcessCoreDataNotifier {
    NSString *channelName = self.crossProcessNotificationChannelName;
    assert(channelName);
    if (!channelName) {
        DDLogError(@"missing channel name");
        return;
    }
    const char *name = [channelName UTF8String];
    notify_register_dispatch(name, &_crossProcessNotificationToken, dispatch_get_main_queue(), ^(int token) {
        uint64_t state;
        notify_get_state(token, &state);
        BOOL isExternal = state != bundleHash();
        if (isExternal) {
            [self handleCrossProcessCoreDataNotificationWithState:state];
        }
    });
}

- (void)handleCrossProcessCoreDataNotificationWithState:(uint64_t)state {
    NSURL *baseURL = self.containerURL;
    NSString *fileName = [NSString stringWithFormat:@"%llu.changes", state];
    NSURL *fileURL = [baseURL URLByAppendingPathComponent:fileName isDirectory:NO];
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    NSDictionary *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:userInfo intoContexts:@[self.viewContext]];
}

- (void)setupCoreDataStackWithContainerURL:(NSURL *)containerURL {
    NSURL *modelURL = [[NSBundle wmf] URLForResource:@"Wikipedia" withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSString *coreDataDBName = @"Wikipedia.sqlite";

    NSURL *coreDataDBURL = [containerURL URLByAppendingPathComponent:coreDataDBName isDirectory:NO];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @YES,
                               NSInferMappingModelAutomaticallyOption: @YES };
    NSError *persistentStoreError = nil;
    if (nil == [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:coreDataDBURL options:options error:&persistentStoreError]) {
        // TODO: Metrics
        DDLogError(@"Error adding persistent store: %@", persistentStoreError);
        NSError *moveError = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSURL *moveURL = [[containerURL URLByAppendingPathComponent:uuid] URLByAppendingPathExtension:@"sqlite"];
        [fileManager moveItemAtURL:coreDataDBURL toURL:moveURL error:&moveError];
        if (moveError) {
            // TODO: Metrics
            [fileManager removeItemAtURL:coreDataDBURL error:nil];
        }
        persistentStoreError = nil;
        if (nil == [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:coreDataDBURL options:options error:&persistentStoreError]) {
            // TODO: Metrics
            DDLogError(@"Second error after adding persistent store: %@", persistentStoreError);
        }
    }

    self.persistentStoreCoordinator = persistentStoreCoordinator;
    self.viewContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.viewContext.persistentStoreCoordinator = persistentStoreCoordinator;
    self.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.viewContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewContextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.viewContext];
}

- (nullable id)archiveableNotificationValueForValue:(id)value {
    if ([value isKindOfClass:[NSManagedObject class]]) {
        return [[value objectID] URIRepresentation];
    } else if ([value isKindOfClass:[NSManagedObjectID class]]) {
        return [value URIRepresentation];
    } else if ([value isKindOfClass:[NSSet class]] || [value isKindOfClass:[NSArray class]]) {
        return [value wmf_map:^id(id obj) {
            return [self archiveableNotificationValueForValue:obj];
        }];
    } else if ([value conformsToProtocol:@protocol(NSCoding)]) {
        return value;
    } else {
        return nil;
    }
}

- (NSDictionary *)archivableNotificationUserInfoForUserInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *archiveableUserInfo = [NSMutableDictionary dictionaryWithCapacity:userInfo.count];
    NSArray *allKeys = userInfo.allKeys;
    for (NSString *key in allKeys) {
        id value = userInfo[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            value = [self archivableNotificationUserInfoForUserInfo:value];
        } else {
            value = [self archiveableNotificationValueForValue:value];
        }
        if (value) {
            archiveableUserInfo[key] = value;
        }
    }
    return archiveableUserInfo;
}

- (void)viewContextDidSave:(NSNotification *)note {
    NSManagedObjectContext *moc = self.viewContext;
    if (!moc) {
        return;
    }

    NSDictionary *userInfo = note.userInfo;
    if (!userInfo) {
        return;
    }

    uint64_t state = bundleHash();

    NSDictionary *archiveableUserInfo = [self archivableNotificationUserInfoForUserInfo:userInfo];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:archiveableUserInfo];
    NSURL *baseURL = [[NSFileManager defaultManager] wmf_containerURL];
    NSString *fileName = [NSString stringWithFormat:@"%llu.changes", state];
    NSURL *fileURL = [baseURL URLByAppendingPathComponent:fileName isDirectory:NO];
    [data writeToURL:fileURL atomically:YES];

    const char *name = [self.crossProcessNotificationChannelName UTF8String];
    notify_set_state(_crossProcessNotificationToken, state);
    notify_post(name);
}

- (void)viewContextDidChange:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    NSArray<NSString *> *keys = @[NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey, NSRefreshedObjectsKey, NSInvalidatedObjectsKey];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    for (NSString *key in keys) {
        NSSet<NSManagedObject *> *changedObjects = userInfo[key];
        for (NSManagedObject *object in changedObjects) {
            if ([object isKindOfClass:[WMFArticle class]]) {
                WMFArticle *article = (WMFArticle *)object;
                NSString *articleKey = article.key;
                NSURL *articleURL = article.URL;
                if (!articleKey || !articleURL) {
                    continue;
                }
                [self.articlePreviewCache removeObjectForKey:articleKey];
                if (![key isEqualToString:NSDeletedObjectsKey]) {
                    [nc postNotificationName:WMFArticleUpdatedNotification object:article];
                }
            }
        }
    }
}

+ (NSString *)legacyYapDatabasePath {
    NSString *databaseName = @"WikipediaYap.sqlite";

    NSURL *baseURL = [[NSFileManager defaultManager] wmf_containerURL];

    NSURL *databaseURL = [baseURL URLByAppendingPathComponent:databaseName isDirectory:NO];

    return databaseURL.filePathURL.path;
}

+ (BOOL)migrateToSharedContainer:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *databaseName = @"WikipediaYap.sqlite";
    NSURL *baseURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                            inDomain:NSUserDomainMask
                                                   appropriateForURL:nil
                                                              create:YES
                                                               error:NULL];

    NSURL *databaseURL = [baseURL URLByAppendingPathComponent:databaseName isDirectory:NO];

    NSString *appSpecificDatabasePath = databaseURL.filePathURL.path;
    NSError *copyError = nil;
    if (![fm copyItemAtPath:appSpecificDatabasePath toPath:[self legacyYapDatabasePath] error:&copyError]) {
        if (copyError.code != NSFileNoSuchFileError && copyError.code != NSFileReadNoSuchFileError) {
            if (error) {
                *error = copyError;
            }
            return NO;
        }
    }

    NSError *moveError = nil;
    if (![fm moveItemAtPath:[MWKDataStore appSpecificMainDataStorePath] toPath:[MWKDataStore mainDataStorePath] error:&moveError]) {
        if (moveError.code != NSFileNoSuchFileError && moveError.code != NSFileReadNoSuchFileError) {
            if (error) {
                *error = moveError;
            }
            return NO;
        }
    }

    return YES;
}

- (void)migrateArticlePreviews:(NSDictionary<NSString *, WMFArticlePreview *> *)articlePreviews historyEntries:(NSDictionary<NSString *, MWKHistoryEntry *> *)historyEntries toManagedObjectContext:(NSManagedObjectContext *)moc {
    if (articlePreviews.count == 0 && historyEntries.count == 0) {
        return;
    }

    NSMutableSet *keysToAdd = [NSMutableSet setWithArray:articlePreviews.allKeys];
    [keysToAdd unionSet:[NSSet setWithArray:historyEntries.allKeys]];

    NSFetchRequest *existingObjectFetchRequest = [WMFArticle fetchRequest];
    existingObjectFetchRequest.predicate = [NSPredicate predicateWithFormat:@"key in %@", keysToAdd];
    NSArray<WMFArticle *> *allExistingObjects = [moc executeFetchRequest:existingObjectFetchRequest error:nil];

    void (^updateBlock)(MWKHistoryEntry *, WMFArticlePreview *, WMFArticle *) = ^(MWKHistoryEntry *entry, WMFArticlePreview *preview, WMFArticle *article) {
        if (entry) {
            article.viewedDate = entry.dateViewed;
            [article updateViewedDateWithoutTime];
            article.viewedFragment = entry.fragment;
            article.viewedScrollPosition = entry.scrollPosition;
            article.savedDate = entry.dateSaved;
            article.isExcludedFromFeed = entry.blackListed;
            article.wasSignificantlyViewed = entry.titleWasSignificantlyViewed;
            article.newsNotificationDate = entry.inTheNewsNotificationDate;
            article.viewedScrollPosition = entry.scrollPosition;
        }
        if (preview) {
            article.displayTitle = preview.displayTitle;
            article.wikidataDescription = preview.wikidataDescription;
            article.snippet = preview.snippet;
            article.thumbnailURL = preview.thumbnailURL;
            article.location = preview.location;
            article.pageViews = preview.pageViews;
        }
    };

    for (WMFArticle *article in allExistingObjects) {
        NSString *key = article.key;
        if (!key) {
            [moc deleteObject:article];
            continue;
        }
        MWKHistoryEntry *entry = historyEntries[key];
        WMFArticlePreview *preview = articlePreviews[key];
        [keysToAdd removeObject:key];
        updateBlock(entry, preview, article);
    }

    NSEntityDescription *articleEntityDescription = [NSEntityDescription entityForName:@"WMFArticle" inManagedObjectContext:moc];
    for (NSString *key in keysToAdd) {
        MWKHistoryEntry *entry = historyEntries[key];
        WMFArticlePreview *preview = articlePreviews[key];
        WMFArticle *article = [[WMFArticle alloc] initWithEntity:articleEntityDescription insertIntoManagedObjectContext:moc];
        article.key = key;
        updateBlock(entry, preview, article);
    }
}

- (void)migrateToQuadKeyLocationIfNecessaryWithCompletion:(nonnull void (^)(NSError *))completion {
    if (![self.articleLocationController needsMigrationWithManagedObjectContext:self.viewContext]) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    [self performBackgroundCoreDataOperationOnATemporaryContext:^(NSManagedObjectContext *moc) {
        [self.articleLocationController migrateWithManagedObjectContext:moc
                                                             completion:^(NSError *_Nullable error) {
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     if (completion) {
                                                                         completion(error);
                                                                     }
                                                                 });
                                                             }];
    }];
}

#pragma mark - Background Contexts

- (void)performBackgroundCoreDataOperationOnATemporaryContext:(nonnull void (^)(NSManagedObjectContext *moc))mocBlock {
    WMFAssertMainThread(@"Background Core Data operations must be started from the main thread.");
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = _viewContext;
    backgroundContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(backgroundContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:backgroundContext];
    [backgroundContext performBlock:^{
        mocBlock(backgroundContext);
        [nc removeObserver:self name:NSManagedObjectContextDidSaveNotification object:backgroundContext];
    }];
}

- (void)backgroundContextDidSave:(NSNotification *)note {
    NSManagedObjectContext *moc = _viewContext;
    [moc performBlockAndWait:^{
        NSError *mainContextSaveError = nil;
        if ([moc hasChanges] && ![moc save:&mainContextSaveError]) {
            DDLogError(@"Error saving main context: %@", mainContextSaveError);
        }
    }];
}

- (NSManagedObjectContext *)feedImportContext {
    WMFAssertMainThread(@"feedImportContext be created on the main thread");
    if (!_feedImportContext) {
        _feedImportContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _feedImportContext.parentContext = _viewContext;
        _feedImportContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:_feedImportContext];
    }
    return _feedImportContext;
}

- (void)teardownFeedImportContext {
    WMFAssertMainThread(@"feedImportContext must be torn down on the main thread");
    if (_feedImportContext) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:_feedImportContext];
        _feedImportContext = nil;
    }
}

#pragma mark - Migrations

- (void)performCoreDataMigrations:(dispatch_block_t)completion {
    if (!self.wasSitesFolderMissing) {
        if (completion) {
            completion();
        }
        return;
    }
    [self performBackgroundCoreDataOperationOnATemporaryContext:^(NSManagedObjectContext *moc) {
        [self markAllDownloadedArticlesInManagedObjectContextAsUndownloaded:moc];
        dispatch_async(dispatch_get_main_queue(), completion);
    }];
}

- (void)markAllDownloadedArticlesInManagedObjectContextAsUndownloaded:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"isDownloaded == YES"];
    request.fetchLimit = 500;
    NSError *fetchError = nil;
    NSArray *downloadedArticles = [moc executeFetchRequest:request error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching downloaded articles: %@", fetchError);
        return;
    }

    while (downloadedArticles.count > 0) {
        @autoreleasepool {
            for (WMFArticle *article in downloadedArticles) {
                article.isDownloaded = NO;
            }

            if ([moc hasChanges]) {
                NSError *saveError = nil;
                [moc save:&saveError];
                if (saveError) {
                    DDLogError(@"Error saving downloaded articles: %@", fetchError);
                    return;
                }
                [moc reset];
            }
        }

        downloadedArticles = [moc executeFetchRequest:request error:&fetchError];
        if (fetchError) {
            DDLogError(@"Error fetching downloaded articles: %@", fetchError);
            return;
        }
    }
}

- (BOOL)migrateToCoreData:(NSError **)error {
    const char *dbPath = [[MWKDataStore legacyYapDatabasePath] UTF8String];
    sqlite3 *db;
    if (sqlite3_open(dbPath, &db) != SQLITE_OK) {
        DDLogError(@"Failed to open legacy db");
        return YES;
    }

    sqlite3_stmt *statement;
    const char *query = "SELECT * FROM database2;";
    if (sqlite3_prepare_v2(db, query, -1, &statement, NULL) != SQLITE_OK) {
        const char *errmsg = sqlite3_errmsg(db);
        DDLogError(@"Failed to prepare query: %s", errmsg);
        return YES;
    }

    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFContinueReadingContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFMainPageContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFRelatedPagesContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFLocationContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFPictureOfTheDayContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFRandomContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFFeaturedArticleContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFTopReadContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFNewsContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFNotificationContentGroup"];
    [NSKeyedUnarchiver setClass:[WMFLegacyContentGroup class] forClassName:@"WMFAnnouncementContentGroup"];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.viewContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:self.viewContext];

    NSManagedObjectContext *moc = self.viewContext;

    NSInteger batchSize = 500;

    NSMutableDictionary *previews = [NSMutableDictionary dictionaryWithCapacity:250];
    NSMutableDictionary *entries = [NSMutableDictionary dictionaryWithCapacity:250];

    while (sqlite3_step(statement) == SQLITE_ROW) {
        @autoreleasepool {
            const unsigned char *collectionNameBytes = sqlite3_column_text(statement, 1);
            int collectionNameBytesLength = sqlite3_column_bytes(statement, 1);
            const unsigned char *keyBytes = sqlite3_column_text(statement, 2);
            int keyBytesLength = sqlite3_column_bytes(statement, 2);
            const void *objectBlob = sqlite3_column_blob(statement, 3);
            int objectBlobLength = sqlite3_column_bytes(statement, 3);
            const void *metadataBlob = sqlite3_column_blob(statement, 4);
            int metadataBlobLength = sqlite3_column_bytes(statement, 4);

            if (collectionNameBytesLength == 0 || keyBytesLength == 0 || objectBlobLength == 0) {
                continue;
            }

            NSString *collectionName = [[NSString alloc] initWithBytes:collectionNameBytes length:collectionNameBytesLength encoding:NSUTF8StringEncoding];
            NSString *key = [[NSString alloc] initWithBytes:keyBytes length:keyBytesLength encoding:NSUTF8StringEncoding];
            NSData *objectData = [[NSData alloc] initWithBytes:objectBlob length:objectBlobLength];
            NSData *metadataData = nil;
            if (metadataBlobLength > 0) {
                metadataData = [[NSData alloc] initWithBytes:metadataBlob length:metadataBlobLength];
            }

            if (!collectionName || !key || !objectData) {
                continue;
            }
            @try {
                if ([collectionName isEqualToString:@"MWKHistoryEntry"]) {
                    MWKHistoryEntry *entry = [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
                    entries[key] = entry;
                } else if ([collectionName isEqualToString:@"WMFArticlePreview"]) {
                    WMFArticlePreview *preview = [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
                    previews[key] = preview;
                } else if ([collectionName isEqualToString:@"WMFContentGroup"]) {
                    WMFLegacyContentGroup *oldContentGroup = [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
                    id metadata = nil;
                    if (metadataData) {
                        metadata = [NSKeyedUnarchiver unarchiveObjectWithData:metadataData];
                    }
                    if (!metadata) {
                        continue;
                    }

                    WMFContentGroupKind contentGroupKind = WMFContentGroupKindUnknown;
                    if ([key hasPrefix:@"wikipedia://content/announcements/"]) {
                        contentGroupKind = WMFContentGroupKindAnnouncement;
                    } else if ([key hasPrefix:@"wikipedia://content/main-page/"]) {
                        contentGroupKind = WMFContentGroupKindMainPage;
                    } else if ([key hasPrefix:@"wikipedia://content/continue-reading/"]) {
                        contentGroupKind = WMFContentGroupKindContinueReading;
                    } else if ([key hasPrefix:@"wikipedia://content/nearby/"]) {
                        contentGroupKind = WMFContentGroupKindLocation;
                    } else if ([key hasPrefix:@"wikipedia://content/picture-of-the-day/"]) {
                        contentGroupKind = WMFContentGroupKindPictureOfTheDay;
                    } else if ([key hasPrefix:@"wikipedia://content/random/"]) {
                        contentGroupKind = WMFContentGroupKindRandom;
                    } else if ([key hasPrefix:@"wikipedia://content/featured-article/"]) {
                        contentGroupKind = WMFContentGroupKindFeaturedArticle;
                    } else if ([key hasPrefix:@"wikipedia://content/notification/"]) {
                        contentGroupKind = WMFContentGroupKindNotification;
                    } else if ([key hasPrefix:@"wikipedia://content/news/"]) {
                        contentGroupKind = WMFContentGroupKindNews;
                    } else if ([key hasPrefix:@"wikipedia://content/top-read/"]) {
                        contentGroupKind = WMFContentGroupKindTopRead;
                    } else if ([key hasPrefix:@"wikipedia://content/related-pages/"]) {
                        contentGroupKind = WMFContentGroupKindRelatedPages;
                    } else {
                        continue;
                    }

                    WMFContentGroup *newContentGroup = [NSEntityDescription insertNewObjectForEntityForName:@"WMFContentGroup" inManagedObjectContext:moc];
                    newContentGroup.contentGroupKind = contentGroupKind;
                    newContentGroup.date = oldContentGroup.date;
                    newContentGroup.midnightUTCDate = oldContentGroup.date.wmf_midnightUTCDateFromUTCDate;
                    newContentGroup.siteURL = oldContentGroup.siteURL;
                    newContentGroup.articleURL = oldContentGroup.articleURL;
                    newContentGroup.location = oldContentGroup.location;
                    newContentGroup.placemark = oldContentGroup.placemark;
                    newContentGroup.contentMidnightUTCDate = oldContentGroup.mostReadDate.wmf_midnightUTCDateFromUTCDate;
                    newContentGroup.wasDismissed = oldContentGroup.wasDismissed;
                    newContentGroup.content = metadata;
                    [newContentGroup updateKey];
                    [newContentGroup updateContentType];
                    [newContentGroup updateDailySortPriority];
                    [newContentGroup updateVisibility];

                    //New key differs from old key, so use the calculated key on newContentGroup rather than the old key
                    NSFetchRequest *request = [WMFContentGroup fetchRequest];
                    request.predicate = [NSPredicate predicateWithFormat:@"key == %@", newContentGroup.key];
                    NSArray *contentGroups = [moc executeFetchRequest:request error:nil];
                    for (WMFContentGroup *group in contentGroups) {
                        if (![group.objectID isEqual:newContentGroup.objectID]) {
                            [moc deleteObject:group];
                        }
                    }
                }
            } @catch (NSException *exception) {
                DDLogError(@"Exception trying to import legacy object for key: %@", key);
            }

            if (entries.count + previews.count > batchSize) {
                [self migrateArticlePreviews:previews historyEntries:entries toManagedObjectContext:moc];
                [entries removeAllObjects];
                [previews removeAllObjects];
                NSError *batchSaveError = nil;
                if (![moc save:&batchSaveError]) {
                    DDLogError(@"Migration batch error: %@", batchSaveError);
                }
                [moc reset];
            }
        }
    }

    if (previews.count + entries.count > 0) {
        [self migrateArticlePreviews:previews historyEntries:entries toManagedObjectContext:moc];
    }

    NSError *saveError = nil;
    BOOL didSave = [moc save:&saveError];
    if (!didSave) {
        if (error) {
            *error = saveError;
        }
        DDLogError(@"Migration batch error: %@", saveError);
    }
    [moc reset];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.viewContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewContextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.viewContext];

    return didSave;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarningWithNotification:(NSNotification *)note {
    [self clearMemoryCache];
}

#pragma - Accessors

- (MWKRecentSearchList *)recentSearchList {
    if (!_recentSearchList) {
        _recentSearchList = [[MWKRecentSearchList alloc] initWithDataStore:self];
    }
    return _recentSearchList;
}

#pragma mark - History and Saved Page List

- (void)setupHistoryAndSavedPageLists {
    WMFAssertMainThread(@"History and saved page lists must be setup on the main thread");
    self.historyList = [[MWKHistoryList alloc] initWithDataStore:self];
    [self.historyList migrateLegacyDataIfNeeded];
    self.savedPageList = [[MWKSavedPageList alloc] initWithDataStore:self];
    [self.savedPageList migrateLegacyDataIfNeeded];
}

#pragma mark - Legacy DataStore

+ (NSString *)mainDataStorePath {
    NSString *documentsFolder = [[NSFileManager defaultManager] wmf_containerPath];
    return [documentsFolder stringByAppendingPathComponent:@"Data"];
}

+ (NSString *)appSpecificMainDataStorePath { //deprecated, use the group folder from mainDataStorePath
    NSString *documentsFolder =
        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentsFolder stringByAppendingPathComponent:@"Data"];
}

- (void)setupLegacyDataStore {
    NSString *pathToExclude = [self pathForSites];
    NSError *directoryCreationError = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:pathToExclude withIntermediateDirectories:YES attributes:nil error:&directoryCreationError]) {
        DDLogError(@"Error creating MWKDataStore path: %@", directoryCreationError);
    }
    NSURL *directoryURL = [NSURL fileURLWithPath:pathToExclude isDirectory:YES];
    NSError *excludeBackupError = nil;
    if (![directoryURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&excludeBackupError]) {
        DDLogError(@"Error excluding MWKDataStore path from backup: %@", excludeBackupError);
    }
    self.articleCache = [[NSCache alloc] init];
    self.articleCache.countLimit = 50;

    self.articlePreviewCache = [[NSCache alloc] init];
    self.articlePreviewCache.countLimit = 100;

    self.cacheRemovalQueue = dispatch_queue_create("org.wikimedia.cache_removal", DISPATCH_QUEUE_SERIAL);
}

#pragma mark - path methods

- (NSString *)joinWithBasePath:(NSString *)path {
    return [self.basePath stringByAppendingPathComponent:path];
}

- (NSString *)pathForSites {
    return [self joinWithBasePath:@"sites"];
}

- (NSString *)pathForDomainInURL:(NSURL *)url {
    NSString *sitesPath = [self pathForSites];
    NSString *domainPath = [sitesPath stringByAppendingPathComponent:url.wmf_domain];
    return [domainPath stringByAppendingPathComponent:url.wmf_language];
}

- (NSString *)pathForArticlesInDomainFromURL:(NSURL *)url {
    NSString *sitePath = [self pathForDomainInURL:url];
    return [sitePath stringByAppendingPathComponent:@"articles"];
}

/// Returns the folder where data for the correspnoding title is stored.
- (NSString *)pathForArticleURL:(NSURL *)url {
    NSString *articlesPath = [self pathForArticlesInDomainFromURL:url];
    NSString *encTitle = [self safeFilenameWithString:url.wmf_titleWithUnderScores];
    return [articlesPath stringByAppendingPathComponent:encTitle];
}

- (NSString *)pathForArticle:(MWKArticle *)article {
    return [self pathForArticleURL:article.url];
}

- (NSString *)pathForSectionsInArticleWithURL:(NSURL *)url {
    NSString *articlePath = [self pathForArticleURL:url];
    return [articlePath stringByAppendingPathComponent:@"sections"];
}

- (NSString *)pathForSectionId:(NSUInteger)sectionId inArticleWithURL:(NSURL *)url {
    NSString *sectionsPath = [self pathForSectionsInArticleWithURL:url];
    NSString *sectionName = [NSString stringWithFormat:@"%d", (int)sectionId];
    return [sectionsPath stringByAppendingPathComponent:sectionName];
}

- (NSString *)pathForSection:(MWKSection *)section {
    return [self pathForSectionId:section.sectionId inArticleWithURL:section.url];
}

- (NSString *)pathForImagesWithArticleURL:(NSURL *)url {
    NSString *articlePath = [self pathForArticleURL:url];
    return [articlePath stringByAppendingPathComponent:@"Images"];
}

- (NSString *)pathForImageURL:(NSString *)imageURL forArticleURL:(NSURL *)articleURL {
    NSString *imagesPath = [self pathForImagesWithArticleURL:articleURL];
    NSString *encURL = [self safeFilenameWithImageURL:imageURL];
    return encURL ? [imagesPath stringByAppendingPathComponent:encURL] : nil;
}

- (NSString *)pathForImage:(MWKImage *)image {
    return [self pathForImageURL:image.sourceURLString forArticleURL:image.article.url];
}

- (NSString *)pathForImageInfoForArticleWithURL:(NSURL *)url {
    return [[self pathForArticleURL:url] stringByAppendingPathComponent:MWKImageInfoFilename];
}

- (NSString *)safeFilenameWithString:(NSString *)str {
    // Escape only % and / with percent style for readability
    NSString *encodedStr = [str stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
    encodedStr = [encodedStr stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];

    return encodedStr;
}

- (NSString *)stringWithSafeFilename:(NSString *)str {
    return [str stringByRemovingPercentEncoding];
}

- (NSString *)safeFilenameWithImageURL:(NSString *)str {
    str = [str wmf_schemelessURL];

    if (![str hasPrefix:MWKDataStoreValidImageSitePrefix]) {
        return nil;
    }

    NSString *suffix = [str substringFromIndex:[MWKDataStoreValidImageSitePrefix length]];
    NSString *fileName = [suffix lastPathComponent];

    // Image URLs are already percent-encoded, so don't double-encode em.
    // In fact, we want to decode them...
    // If we don't, long Unicode filenames may not fit in the filesystem.
    NSString *decodedFileName = [fileName stringByRemovingPercentEncoding];

    return decodedFileName;
}

#pragma mark - save methods

- (BOOL)ensurePathExists:(NSString *)path error:(NSError **)error {
    return [[NSFileManager defaultManager] createDirectoryAtPath:path
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:error];
}

- (void)ensurePathExists:(NSString *)path {
    [self ensurePathExists:path error:NULL];
}

- (BOOL)saveData:(NSData *)data toFile:(NSString *)filename atPath:(NSString *)path error:(NSError **)error {
    NSAssert([filename length] > 0, @"No file path given for saving data");
    if (!filename) {
        return NO;
    }
    [self ensurePathExists:path error:error];
    NSString *absolutePath = [path stringByAppendingPathComponent:filename];
    return [data writeToFile:absolutePath options:NSDataWritingAtomic error:error];
}

- (void)saveData:(NSData *)data path:(NSString *)path name:(NSString *)name {
    NSError *error = nil;
    [self saveData:data toFile:name atPath:path error:&error];
    NSAssert(error == nil, @"Error saving image to data store: %@", error);
}

- (BOOL)saveArray:(NSArray *)array path:(NSString *)path name:(NSString *)name error:(NSError **)error {
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:array format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    return [self saveData:data toFile:name atPath:path error:error];
}

- (void)saveArray:(NSArray *)array path:(NSString *)path name:(NSString *)name {
    [self saveArray:array path:path name:name error:NULL];
}

- (BOOL)saveDictionary:(NSDictionary *)dict path:(NSString *)path name:(NSString *)name error:(NSError **)error {
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    return [self saveData:data toFile:name atPath:path error:error];
}

- (void)saveDictionary:(NSDictionary *)dict path:(NSString *)path name:(NSString *)name {
    [self saveDictionary:dict path:path name:name error:NULL];
}

- (BOOL)saveString:(NSString *)string path:(NSString *)path name:(NSString *)name error:(NSError **)error {
    return [self saveData:[string dataUsingEncoding:NSUTF8StringEncoding] toFile:name atPath:path error:error];
}

- (void)saveString:(NSString *)string path:(NSString *)path name:(NSString *)name {
    [self saveString:string path:path name:name error:NULL];
}

- (void)saveArticle:(MWKArticle *)article {
    if (article.url.wmf_title == nil) {
        return;
    }

    if (article.url.wmf_isNonStandardURL) {
        return;
    }
    [self addArticleToMemoryCache:article];
    NSString *path = [self pathForArticle:article];
    NSDictionary *export = [article dataExport];
    [self saveDictionary:export path:path name:@"Article.plist"];
}

- (void)saveSection:(MWKSection *)section {
    NSString *path = [self pathForSection:section];
    NSDictionary *export = [section dataExport];
    [self saveDictionary:export path:path name:@"Section.plist"];
}

- (void)saveSectionText:(NSString *)html section:(MWKSection *)section {
    NSString *path = [self pathForSection:section];
    [self saveString:html path:path name:@"Section.html"];
}

- (void)saveImage:(MWKImage *)image {
    if ([image.article isMain]) {
        return;
    }
    NSString *path = [self pathForImage:image];
    NSDictionary *export = [image dataExport];
    [self saveDictionary:export path:path name:@"Image.plist"];
}

- (BOOL)saveRecentSearchList:(MWKRecentSearchList *)list error:(NSError **)error {
    NSString *path = self.basePath;
    NSDictionary *export = @{ @"entries": [list dataExport] };
    return [self saveDictionary:export path:path name:@"RecentSearches.plist" error:error];
}

- (void)saveImageInfo:(NSArray *)imageInfo forArticleURL:(NSURL *)url {
    NSArray *export = [imageInfo wmf_map:^id(MWKImageInfo *obj) {
        return [obj dataExport];
    }];

    [self saveArray:export
               path:[self pathForArticleURL:url]
               name:MWKImageInfoFilename];
}

- (void)addArticleToMemoryCache:(MWKArticle *)article forKey:(NSString *)key {
    if (!key || !article) {
        return;
    }
    @synchronized(self.articleCache) {
        [self.articleCache setObject:article forKey:key];
    }
}

- (void)addArticleToMemoryCache:(MWKArticle *)article {
    [self addArticleToMemoryCache:article forKey:article.url.wmf_articleDatabaseKey];
}

#pragma mark - load methods

- (MWKArticle *)memoryCachedArticleWithKey:(NSString *)key {
    return [self.articleCache objectForKey:key];
}

- (MWKArticle *)memoryCachedArticleWithURL:(NSURL *)url {
    return [self memoryCachedArticleWithKey:url.wmf_articleDatabaseKey];
}

- (nullable MWKArticle *)existingArticleWithURL:(NSURL *)url {
    NSString *key = [url wmf_articleDatabaseKey];
    MWKArticle *existingArticle =
        [self memoryCachedArticleWithKey:key] ?: [self articleFromDiskWithURL:url];
    if (existingArticle) {
        [self addArticleToMemoryCache:existingArticle forKey:key];
    }
    return existingArticle;
}

- (MWKArticle *)articleFromDiskWithURL:(NSURL *)url {
    NSString *path = [self pathForArticleURL:url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Article.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (!dict) {
        return nil;
    }
    return [[MWKArticle alloc] initWithURL:url dataStore:self dict:dict];
}

- (MWKArticle *)articleWithURL:(NSURL *)url {
    MWKArticle *article = [self existingArticleWithURL:url];
    if (!article) {
        article = [[MWKArticle alloc] initWithURL:url dataStore:self];
    }
    return article;
}

- (MWKSection *)sectionWithId:(NSUInteger)sectionId article:(MWKArticle *)article {
    NSString *path = [self pathForSectionId:sectionId inArticleWithURL:article.url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Section.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return [[MWKSection alloc] initWithArticle:article dict:dict];
}

- (NSString *)sectionTextWithId:(NSUInteger)sectionId article:(MWKArticle *)article {
    NSString *path = [self pathForSectionId:sectionId inArticleWithURL:article.url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Section.html"];

    NSError *err;
    NSString *html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        return nil;
    }

    return html;
}

- (BOOL)hasHTMLFileForSection:(MWKSection *)section {
    NSString *path = [self pathForSectionId:section.sectionId inArticleWithURL:section.article.url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Section.html"];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (nullable MWKImage *)imageWithURL:(NSString *)url article:(MWKArticle *)article {
    if (url == nil) {
        return nil;
    }
    NSString *path = [self pathForImageURL:url forArticleURL:article.url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Image.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKImage alloc] initWithArticle:article dict:dict];
    } else {
        // Not 100% sure if we should return an object here or not,
        // but it seems useful to do so.
        return [[MWKImage alloc] initWithArticle:article sourceURLString:url];
    }
}

- (NSArray *)historyListData {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"History.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return dict[@"entries"];
}

- (NSDictionary *)savedPageListData {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"SavedPages.plist"];
    return [NSDictionary dictionaryWithContentsOfFile:filePath];
}

- (NSArray *)recentSearchListData {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"RecentSearches.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return dict[@"entries"];
}

- (NSArray<NSURL *> *)cacheRemovalListFromDisk {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"TitlesToRemove.plist"];
    NSArray *URLStrings = [NSArray arrayWithContentsOfFile:filePath];
    NSArray<NSURL *> *urls = [URLStrings wmf_mapAndRejectNil:^NSURL *(id obj) {
        if (obj && [obj isKindOfClass:[NSString class]]) {
            return [NSURL URLWithString:obj];
        } else {
            return nil;
        }
    }];
    return urls;
}

- (BOOL)saveCacheRemovalListToDisk:(NSArray<NSURL *> *)cacheRemovalList error:(NSError **)error {
    NSArray *URLStrings = [cacheRemovalList wmf_map:^id(NSURL *obj) {
        return [obj absoluteString];
    }];
    return [self saveArray:URLStrings path:self.basePath name:@"TitlesToRemove.plist" error:error];
}

- (NSArray *)imageInfoForArticleWithURL:(NSURL *)url {
    return [[NSArray arrayWithContentsOfFile:[self pathForImageInfoForArticleWithURL:url]] wmf_mapAndRejectNil:^MWKImageInfo *(id obj) {
        return [MWKImageInfo imageInfoWithExportedData:obj];
    }];
}

#pragma mark - helper methods

- (void)removeUnreferencedArticlesFromDiskCacheWithFailure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    [self performBackgroundCoreDataOperationOnATemporaryContext:^(NSManagedObjectContext *moc) {
        NSFetchRequest *articlesWithHTMLInTitlesFetchRequest = [WMFArticle fetchRequest];
        articlesWithHTMLInTitlesFetchRequest.predicate = [NSPredicate predicateWithFormat:@"displayTitle CONTAINS '<' || wikidataDescription CONTAINS '<'"];
        NSError *htmlFetchError = nil;
        NSArray *articlesWithHTMLInTheTitle = [moc executeFetchRequest:articlesWithHTMLInTitlesFetchRequest error:&htmlFetchError];
        if (htmlFetchError) {
            DDLogError(@"Error fetching articles with HTML in the title: %@", htmlFetchError);
        }

        for (WMFArticle *article in articlesWithHTMLInTheTitle) {
            article.displayTitle = [article.displayTitle wmf_stringByRemovingHTML];
            article.wikidataDescription = [article.wikidataDescription wmf_stringByRemovingHTML];
        }

        NSError *saveError = nil;
        [moc save:&saveError];
        if (saveError) {
            DDLogError(@"Error saving after fixing articles with HTML in the title: %@", saveError);
        }

        NSFetchRequest *allValidArticleKeysFetchRequest = [WMFArticle fetchRequest];
        allValidArticleKeysFetchRequest.predicate = [NSPredicate predicateWithFormat:@"savedDate != NULL"];
        allValidArticleKeysFetchRequest.resultType = NSDictionaryResultType;
        allValidArticleKeysFetchRequest.propertiesToFetch = @[@"key"];

        NSError *fetchError = nil;
        NSArray *arrayOfAllValidArticleDictionaries = [moc executeFetchRequest:allValidArticleKeysFetchRequest error:&fetchError];

        if (fetchError) {
            failure(fetchError);
            return;
        }

        dispatch_block_t deleteEverythingAndSucceed = ^{
            dispatch_async(self.cacheRemovalQueue, ^{
                [[NSFileManager defaultManager] removeItemAtPath:[self pathForSites] error:nil];
                dispatch_async(dispatch_get_main_queue(), success);
            });
        };

        if (arrayOfAllValidArticleDictionaries.count == 0) {
            deleteEverythingAndSucceed();
            return;
        }

        NSMutableSet *allValidArticleKeys = [NSMutableSet setWithCapacity:arrayOfAllValidArticleDictionaries.count];
        for (NSDictionary *article in arrayOfAllValidArticleDictionaries) {
            NSString *key = article[@"key"];
            if (!key) {
                continue;
            }
            [allValidArticleKeys addObject:key];
        }

        if (allValidArticleKeys.count == 0) {
            deleteEverythingAndSucceed();
            return;
        }

        dispatch_async(self.cacheRemovalQueue, ^{
            NSMutableArray<NSURL *> *articleURLsToRemove = [NSMutableArray arrayWithCapacity:10];
            [self iterateOverArticleURLs:^(NSURL *articleURL) {
                NSString *key = articleURL.wmf_articleDatabaseKey;
                if (!key) {
                    return;
                }
                if ([allValidArticleKeys containsObject:key]) {
                    return;
                }

                [articleURLsToRemove addObject:articleURL];
            }];
            [self removeArticlesWithURLsFromCache:articleURLsToRemove];
            dispatch_async(dispatch_get_main_queue(), success);
        });
    }];
}

- (void)iterateOverArticleURLs:(void (^)(NSURL *))block {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *articlePath = [self pathForSites];
    for (NSString *path in [fm enumeratorAtPath:articlePath]) {
        NSArray *components = [path pathComponents];

        //HAX: We make assumptions about the length of paths below.
        //This is due to our title handling assumptions
        WMF_TECH_DEBT_TODO(We should remove this when we move to a DB)
        if ([components count] < 5) {
            continue;
        }

        NSUInteger count = [components count];
        NSString *filename = components[count - 1];
        if ([filename isEqualToString:@"Article.plist"]) {
            NSString *dirname = components[count - 2];
            NSString *titleText = [self stringWithSafeFilename:dirname];

            NSString *language = components[count - 4];
            NSString *domain = components[count - 5];

            NSURL *url = [NSURL wmf_URLWithDomain:domain language:language title:titleText fragment:nil];
            block(url);
        }
    }
}

- (void)startCacheRemoval:(dispatch_block_t)completion {
    dispatch_async(self.cacheRemovalQueue, ^{
        if (!self.isCacheRemovalActive) {
            self.cacheRemovalActive = true;
            self.cacheRemovalCompletion = completion;
            [self removeNextArticleFromCacheRemovalList];
        } else {
            dispatch_block_t existingCompletion = self.cacheRemovalCompletion;
            self.cacheRemovalCompletion = ^{
                if (existingCompletion) {
                    existingCompletion();
                }
                if (completion) {
                    completion();
                }
            };
        }
    });
}

- (void)_stopCacheRemoval {
    dispatch_block_t completion = self.cacheRemovalCompletion;
    if (completion) {
        completion();
    }
    self.cacheRemovalActive = false;
    self.cacheRemovalCompletion = nil;
}

- (void)stopCacheRemoval {
    dispatch_sync(self.cacheRemovalQueue, ^{
        [self _stopCacheRemoval];
    });
}

- (void)removeNextArticleFromCacheRemovalList {
    if (!self.cacheRemovalActive) {
        return;
    }
    NSMutableArray<NSURL *> *urlsOfArticlesToRemove = [[self cacheRemovalListFromDisk] mutableCopy];
    if (urlsOfArticlesToRemove.count == 0) {
        [self _stopCacheRemoval];
        return;
    }
    NSURL *urlToRemove = urlsOfArticlesToRemove[0];
    [self removeArticleWithURL:urlToRemove
        fromDiskWithCompletion:^{
            dispatch_async(self.cacheRemovalQueue, ^{
                [urlsOfArticlesToRemove removeObjectAtIndex:0];
                NSError *error = nil;
                if ([self saveCacheRemovalListToDisk:urlsOfArticlesToRemove error:&error]) {
                    dispatch_async(self.cacheRemovalQueue, ^{
                        [self removeNextArticleFromCacheRemovalList];
                    });
                } else {
                    DDLogError(@"Error saving cache removal list: %@", error);
                }
            });
        }];
}

- (void)removeArticlesWithURLsFromCache:(NSArray<NSURL *> *)urlsToRemove {
    if (urlsToRemove.count == 0) {
        return;
    }
    dispatch_async(self.cacheRemovalQueue, ^{
        NSMutableArray<NSURL *> *allURLsToRemove = [[self cacheRemovalListFromDisk] mutableCopy];
        if (allURLsToRemove == nil) {
            allURLsToRemove = [NSMutableArray arrayWithArray:urlsToRemove];
        } else {
            [allURLsToRemove addObjectsFromArray:urlsToRemove];
        }
        NSError *error = nil;
        if (![self saveCacheRemovalListToDisk:allURLsToRemove error:&error]) {
            DDLogError(@"Error saving cache removal list to disk: %@", error);
        }
    });
}

- (NSArray *)legacyImageURLsForArticle:(MWKArticle *)article {
    NSString *path = [self pathForArticle:article];
    NSDictionary *legacyImageDictionary = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"Images.plist"]];
    if ([legacyImageDictionary isKindOfClass:[NSDictionary class]]) {
        NSArray *legacyImageURLStrings = [legacyImageDictionary objectForKey:@"entries"];
        if ([legacyImageURLStrings isKindOfClass:[NSArray class]]) {
            NSArray *legacyImageURLs = [legacyImageURLStrings wmf_mapAndRejectNil:^id(id obj) {
                if ([obj isKindOfClass:[NSString class]]) {
                    return [NSURL URLWithString:obj];
                } else {
                    return nil;
                }
            }];
            return legacyImageURLs;
        }
    }
    return @[];
}

#pragma mark - Deletion

- (NSError *)removeFolderAtBasePath {
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:self.basePath error:&err];
    return err;
}

- (void)removeArticleWithURL:(NSURL *)articleURL fromDiskWithCompletion:(dispatch_block_t)completion {
    if (!articleURL) {
        if (completion) {
            completion();
        }
        return;
    }
    dispatch_async(self.cacheRemovalQueue, ^{
        NSString *path = [self pathForArticleURL:articleURL];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        dispatch_block_t combinedCompletion = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                WMFArticle *article = [self fetchArticleWithURL:articleURL];
                article.isDownloaded = NO;
                NSError *saveError = nil;
                if (![self save:&saveError]) {
                    DDLogError(@"Error saving after cache removal: %@", saveError);
                }
                if (completion) {
                    completion();
                }
            });
        };
        NSString *groupKey = articleURL.wmf_articleDatabaseKey;
        if (groupKey) {
            [[WMFImageController sharedInstance] removePermanentlyCachedImagesWithGroupKey:groupKey completion:combinedCompletion];
        } else {
            combinedCompletion();
        }
    });
}

#pragma mark - Cache

- (void)clearMemoryCache {
    @synchronized(self.articleCache) {
        [self.articleCache removeAllObjects];
    }
    [self.articlePreviewCache removeAllObjects];
}

#pragma mark - Core Data

#if DEBUG
- (NSManagedObjectContext *)viewContext {
    NSAssert([NSThread isMainThread], @"View context must only be accessed on the main thread");
    return _viewContext;
}
#endif

- (BOOL)save:(NSError **)error {
    if (![self.viewContext hasChanges]) {
        return YES;
    }
    return [self.viewContext save:error];
}

- (nullable WMFArticle *)fetchArticleWithURL:(NSURL *)URL inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    return [self fetchArticleWithKey:[URL wmf_articleDatabaseKey] inManagedObjectContext:moc];
}

- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    WMFArticle *article = nil;
    if (moc == self.viewContext) {
        article = [self.articlePreviewCache objectForKey:key];
        if (article) {
            return article;
        }
    }
    article = [moc fetchArticleWithKey:key];
    if (article && moc == self.viewContext) {
        [self.articlePreviewCache setObject:article forKey:key];
    }
    return article;
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSString *language = URL.wmf_language;
    NSString *title = URL.wmf_title;
    NSString *key = [URL wmf_articleDatabaseKey];
    if (!language || !title || !key) {
        return nil;
    }
    WMFArticle *article = [self fetchArticleWithKey:key inManagedObjectContext:moc];
    if (!article) {
        article = [[WMFArticle alloc] initWithEntity:[NSEntityDescription entityForName:@"WMFArticle" inManagedObjectContext:moc] insertIntoManagedObjectContext:moc];
        article.key = key;
        if (moc == self.viewContext) {
            [self.articlePreviewCache setObject:article forKey:key];
        }
    }
    return article;
}

- (nullable WMFArticle *)fetchArticleWithURL:(NSURL *)URL {
    return [self fetchArticleWithKey:[URL wmf_articleDatabaseKey]];
}

- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key {
    WMFAssertMainThread(@"Article fetch must be performed on the main thread.");
    return [self fetchArticleWithKey:key inManagedObjectContext:self.viewContext];
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL {
    WMFAssertMainThread(@"Article fetch must be performed on the main thread.");
    return [self fetchOrCreateArticleWithURL:URL inManagedObjectContext:self.viewContext];
}

- (void)setIsExcludedFromFeed:(BOOL)isExcludedFromFeed withArticleURL:(NSURL *)articleURL inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSParameterAssert(articleURL);
    if ([articleURL wmf_isNonStandardURL]) {
        return;
    }
    if ([articleURL.wmf_title length] == 0) {
        return;
    }

    WMFArticle *article = [self fetchOrCreateArticleWithURL:articleURL inManagedObjectContext:moc];
    article.isExcludedFromFeed = isExcludedFromFeed;
    [self save:nil];
}

- (BOOL)isArticleWithURLExcludedFromFeed:(NSURL *)articleURL inManagedObjectContext:(NSManagedObjectContext *)moc {
    WMFArticle *article = [self fetchArticleWithURL:articleURL inManagedObjectContext:moc];
    if (!article) {
        return NO;
    }
    return article.isExcludedFromFeed;
}

- (void)setIsExcludedFromFeed:(BOOL)isExcludedFromFeed withArticleURL:(NSURL *)articleURL {
    [self setIsExcludedFromFeed:isExcludedFromFeed withArticleURL:articleURL inManagedObjectContext:self.viewContext];
}

- (BOOL)isArticleWithURLExcludedFromFeed:(NSURL *)articleURL {
    return [self isArticleWithURLExcludedFromFeed:articleURL inManagedObjectContext:self.viewContext];
}

@end
