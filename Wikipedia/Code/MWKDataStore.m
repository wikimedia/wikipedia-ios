#import <WMF/WMF-Swift.h>
#import <WMF/WMFCrossProcessCoreDataSynchronizer.h>
#import "WMFAnnouncement.h"

@import CoreData;

// Emitted when article state changes. Can be used for things such as being notified when article 'saved' state changes.
NSString *const WMFArticleUpdatedNotification = @"WMFArticleUpdatedNotification";
NSString *const WMFArticleDeletedNotification = @"WMFArticleDeletedNotification";
NSString *const WMFArticleDeletedNotificationUserInfoArticleKeyKey = @"WMFArticleDeletedNotificationUserInfoArticleKeyKey";
NSString *const WMFBackgroundContextDidSave = @"WMFBackgroundContextDidSave";
NSString *const WMFFeedImportContextDidSave = @"WMFFeedImportContextDidSave";
NSString *const WMFViewContextDidSave = @"WMFViewContextDidSave";

NSString *const WMFLibraryVersionKey = @"WMFLibraryVersion";
static const NSInteger WMFCurrentLibraryVersion = 12;

NSString *const MWKDataStoreValidImageSitePrefix = @"//upload.wikimedia.org/";

NSString *const WMFCoreDataSynchronizerInfoFileName = @"Wikipedia.info";

NSString *const WMFMainContextCrossProcessNotificiationChannelNameKey = @"CrossProcessNotificiationChannelName";
NSString *const WMFMainContextCrossProcessNotificationChannelNamePrefix = @"org.wikimedia.wikipedia.cd-cpn-";

NSString *const WMFCacheContextCrossProcessNotificiationChannelNameKey = @"CacheContextCrossProcessNotificiationChannelName";
NSString *const WMFCacheContextCrossProcessNotificiationChannelNamePrefix = @"org.wikimedia.wikipedia.cache-cd-cpn-";

NSString *MWKCreateImageURLWithPath(NSString *path) {
    return [MWKDataStoreValidImageSitePrefix stringByAppendingString:path];
}

@interface MWKDataStore () <WMFAuthenticationManagerDelegate, WMFSessionAuthenticationDelegate>

@property (nonatomic, strong) WMFSession *session;
@property (nonatomic, strong) WMFConfiguration *configuration;
@property (nonatomic, strong) WMFAuthenticationManager *authenticationManager;

@property (readwrite, strong, nonatomic) MWKSavedPageList *savedPageList;
@property (readwrite, strong, nonatomic) MWKRecentSearchList *recentSearchList;

@property (nonatomic, strong) WMFReadingListsController *readingListsController;
@property (nonatomic, strong) WMFExploreFeedContentController *feedContentController;
@property (nonatomic, strong) WikidataDescriptionEditingController *wikidataDescriptionEditingController;
@property (nonatomic, strong) RemoteNotificationsController *remoteNotificationsController;
@property (nonatomic, strong) WMFArticleSummaryController *articleSummaryController;
@property (nonatomic, strong) MWKLanguageLinkController *languageLinkController;
@property (nonatomic, strong) WMFNotificationsController *notificationsController;

@property (nonatomic, strong) MobileviewToMobileHTMLConverter *mobileviewConverter;

@property (readwrite, copy, nonatomic) NSString *basePath;
@property (readwrite, strong, nonatomic) NSCache *articleCache;

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *viewContext;
@property (nonatomic, strong) NSManagedObjectContext *feedImportContext;

@property (nonatomic, strong) WMFPermanentCacheController *cacheController;

@property (nonatomic, strong) WMFCrossProcessCoreDataSynchronizer *librarySynchronizer;
@property (nonatomic, strong) WMFCrossProcessCoreDataSynchronizer *cacheSynchronizer;

@property (nonatomic, strong) NSURL *containerURL;

@property (readwrite, nonatomic) RemoteConfigOption remoteConfigsThatFailedUpdate;

@property (readwrite, strong, nonatomic) WMFABTestsController *abTestsController;

@end

@implementation MWKDataStore

+ (MWKDataStore *)shared {
    static dispatch_once_t onceToken;
    static MWKDataStore *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopCoreDataSynchronizers];
}

- (instancetype)init {
    self = [self initWithContainerURL:[[NSFileManager defaultManager] wmf_containerURL]];
    return self;
}

- (instancetype)initWithContainerURL:(NSURL *)containerURL {
    self = [super init];
    if (self) {
        WMFConfiguration *configuration = [WMFConfiguration current];
        WMFSession *session = [[WMFSession alloc] initWithConfiguration:configuration];
        session.authenticationDelegate = self;
        WMFAuthenticationManager *authenticationManager = [[WMFAuthenticationManager alloc] initWithSession:session configuration:configuration];
        authenticationManager.delegate = self;
        self.session = session;
        self.configuration = configuration;
        self.authenticationManager = authenticationManager;
        self.containerURL = containerURL;
        self.basePath = [self.containerURL URLByAppendingPathComponent:@"Data" isDirectory:YES].path;
        [self setupLegacyDataStore];
        [self setupCoreDataStackWithContainerURL:containerURL];
        [self setupCoreDataSynchronizersWithContainerURL:containerURL];
        [self startSynchronizingLibraryContexts];
        [self setupHistoryAndSavedPageLists];
        self.languageLinkController = [[MWKLanguageLinkController alloc] initWithManagedObjectContext:self.viewContext];
        self.feedContentController = [[WMFExploreFeedContentController alloc] initWithDataStore:self];
        [self.feedContentController updateContentSources];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarningWithNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        self.wikidataDescriptionEditingController = [[WikidataDescriptionEditingController alloc] initWithSession:session configuration:configuration];
        self.remoteNotificationsController = [[RemoteNotificationsController alloc] initWithSession:session configuration:configuration preferredLanguageCodesProvider:self.languageLinkController];
        self.notificationsController = [[WMFNotificationsController alloc] initWithDataStore:self];
        self.articleSummaryController = [[WMFArticleSummaryController alloc] initWithSession:session configuration:configuration dataStore:self];
        self.mobileviewConverter = [[MobileviewToMobileHTMLConverter alloc] init];
    }
    return self;
}

- (void)teardown:(nullable dispatch_block_t)completion {
    [self stopCoreDataSynchronizers];
    [self.session teardown];
    if (self.cacheController) {
        [self.cacheController teardown:^{
            if (completion) {
                completion();
            }
        }];
    } else if (completion) {
        completion();
    }
}

/// Generates a globally unique cross process notification channel name with the given prefix
- (NSString *)uniqueCrossProcessNotificationChannelNameWithPrefix:(NSString *)prefix {
    NSUUID *uuid = [NSUUID new];
    NSString *uuidString = uuid.UUIDString;
    return [NSString stringWithFormat:@"%@%@", prefix, uuidString].lowercaseString;
}

- (void)setupCoreDataSynchronizersWithContainerURL:(NSURL *)containerURL {
    NSURL *infoDictionaryURL = [containerURL URLByAppendingPathComponent:WMFCoreDataSynchronizerInfoFileName isDirectory:NO];
    NSError *unarchiveError = nil;
    NSMutableDictionary *infoDictionary = [[self unarchivedDictionaryFromFileURL:infoDictionaryURL error:&unarchiveError] mutableCopy] ?: [NSMutableDictionary new];
    if (unarchiveError) {
        DDLogError(@"Error unarchiving shared info dictionary: %@", unarchiveError);
    }

    BOOL needsWrite = false;

    // The main cross process notification channel is for the main core data stack (articles, feed, library values, etc)
    NSString *key = WMFMainContextCrossProcessNotificiationChannelNameKey;
    if (!infoDictionary[key]) {
        infoDictionary[key] = [self uniqueCrossProcessNotificationChannelNameWithPrefix:WMFMainContextCrossProcessNotificationChannelNamePrefix];
        needsWrite = YES;
    }
    self.librarySynchronizer = [[WMFCrossProcessCoreDataSynchronizer alloc] initWithIdentifier:infoDictionary[key] storageDirectory:containerURL];

    // The cache context cross process notification channel is for the cache's core data stack (cached images, offline article content)
    key = WMFCacheContextCrossProcessNotificiationChannelNameKey;
    if (!infoDictionary[key]) {
        infoDictionary[key] = [self uniqueCrossProcessNotificationChannelNameWithPrefix:WMFCacheContextCrossProcessNotificiationChannelNamePrefix];
        needsWrite = YES;
    }
    self.cacheSynchronizer = [[WMFCrossProcessCoreDataSynchronizer alloc] initWithIdentifier:infoDictionary[key] storageDirectory:containerURL];

    if (needsWrite) {
        NSError *archiveError = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:infoDictionary requiringSecureCoding:false error:&archiveError];
        if (archiveError) {
            DDLogError(@"Error archiving shared info dictionary: %@", archiveError);
        }
        [data writeToURL:infoDictionaryURL atomically:YES];
    }
}

- (void)startSynchronizingLibraryContexts {
    [self.librarySynchronizer startSynchronizingContexts:@[self.viewContext]];
}

- (void)startSynchronizingCacheContext:(NSManagedObjectContext *)moc {
    [self.cacheSynchronizer startSynchronizingContexts:@[moc]];
}

- (void)stopCoreDataSynchronizers {
    [self.librarySynchronizer stop];
    [self.cacheSynchronizer stop];
}

- (NSDictionary *)unarchivedDictionaryFromFileURL:(NSURL *)fileURL error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    NSSet *allowedClasses = [NSSet setWithArray:[NSSecureUnarchiveFromDataTransformer allowedTopLevelClasses]];
    return [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses fromData:data error:error];
}

- (void)setupCoreDataStackWithContainerURL:(NSURL *)containerURL {
    NSURL *modelURL = [[NSBundle wmf] URLForResource:@"Wikipedia" withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSString *coreDataDBName = @"Wikipedia.sqlite";

    NSURL *coreDataDBURL = [containerURL URLByAppendingPathComponent:coreDataDBName isDirectory:NO];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES};
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
    self.viewContext.automaticallyMergesChangesFromParent = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.viewContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewContextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.viewContext];
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
                WMFInMemoryURLKey *articleKey = article.inMemoryKey;
                NSURL *articleURL = article.URL;
                if (!articleKey || !articleURL) {
                    continue;
                }
                [self.articleCache removeObjectForKey:articleKey];
                if ([key isEqualToString:NSDeletedObjectsKey]) { // Could change WMFArticleUpdatedNotification to use UserInfo for consistency but want to keep change set minimal at this point
                    [nc postNotificationName:WMFArticleDeletedNotification object:[note object] userInfo:@{WMFArticleDeletedNotificationUserInfoArticleKeyKey: articleKey}];
                } else {
                    [nc postNotificationName:WMFArticleUpdatedNotification object:article];
                }
            }
        }
    }
}

#pragma mark - Background Contexts

- (void)managedObjectContextDidSave:(NSNotification *)note {
    NSManagedObjectContext *moc = note.object;
    NSNotificationName notificationName;
    if (moc == _viewContext) {
        notificationName = WMFViewContextDidSave;
    } else if (moc == _feedImportContext) {
        notificationName = WMFFeedImportContextDidSave;
    } else {
        notificationName = WMFBackgroundContextDidSave;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:note.object userInfo:note.userInfo];
}

- (void)performBackgroundCoreDataOperationOnATemporaryContext:(nonnull void (^)(NSManagedObjectContext *moc))mocBlock {
    WMFAssertMainThread(@"Background Core Data operations must be started from the main thread.");
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.persistentStoreCoordinator = _persistentStoreCoordinator;
    backgroundContext.automaticallyMergesChangesFromParent = YES;
    backgroundContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:backgroundContext];
    [backgroundContext performBlock:^{
        mocBlock(backgroundContext);
        [nc removeObserver:self name:NSManagedObjectContextDidSaveNotification object:backgroundContext];
    }];
}

- (NSManagedObjectContext *)feedImportContext {
    WMFAssertMainThread(@"feedImportContext must be created on the main thread");
    if (!_feedImportContext) {
        _feedImportContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _feedImportContext.persistentStoreCoordinator = _persistentStoreCoordinator;
        _feedImportContext.automaticallyMergesChangesFromParent = YES;
        _feedImportContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:_feedImportContext];
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

- (BOOL)migrateToReadingListsInManagedObjectContext:(NSManagedObjectContext *)moc error:(NSError **)migrationError {
    ReadingList *defaultReadingList = [moc wmf_fetchOrCreateDefaultReadingList];
    if (!defaultReadingList) {
        defaultReadingList = [[ReadingList alloc] initWithContext:moc];
        defaultReadingList.canonicalName = [ReadingList defaultListCanonicalName];
        defaultReadingList.isDefault = YES;
    }

    for (ReadingListEntry *entry in defaultReadingList.entries) {
        entry.isUpdatedLocally = YES;
    }

    if ([moc hasChanges] && ![moc save:migrationError]) {
        return NO;
    }

    NSFetchRequest<WMFArticle *> *request = [WMFArticle fetchRequest];
    request.fetchLimit = 500;
    request.predicate = [NSPredicate predicateWithFormat:@"savedDate != NULL && readingLists.@count == 0", defaultReadingList];

    NSArray<WMFArticle *> *results = [moc executeFetchRequest:request error:migrationError];
    if (!results) {
        return NO;
    }

    NSError *addError = nil;

    while (results.count > 0) {
        for (WMFArticle *article in results) {
            [self.readingListsController addArticleToDefaultReadingList:article error:&addError];
            if (addError) {
                break;
            }
        }
        if (addError) {
            break;
        }
        if (![moc save:migrationError]) {
            return NO;
        }
        [moc reset];
        defaultReadingList = [moc wmf_fetchOrCreateDefaultReadingList]; // needs to re-fetch after reset
        results = [moc executeFetchRequest:request error:migrationError];
        if (!defaultReadingList || !results) {
            return NO;
        }
    }
    if (addError) {
        DDLogError(@"Error adding to default reading list: %@", addError);
    } else {
        [moc wmf_setValue:@(5) forKey:WMFLibraryVersionKey];
    }

    return [moc save:migrationError];
}

- (BOOL)migrateMainPageContentGroupInManagedObjectContext:(NSManagedObjectContext *)moc error:(NSError **)migrationError {
    NSArray *mainPages = [moc contentGroupsOfKind:WMFContentGroupKindMainPage];
    for (WMFContentGroup *mainPage in mainPages) {
        [moc deleteObject:mainPage];
    }
    [moc wmf_setValue:@(6) forKey:WMFLibraryVersionKey];
    return [moc save:migrationError];
}

- (void)performUpdatesFromLibraryVersion:(NSUInteger)currentLibraryVersion inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSError *migrationError = nil;

    if (currentLibraryVersion < 5) {
        if (![self migrateToReadingListsInManagedObjectContext:moc error:&migrationError]) {
            DDLogError(@"Error during migration: %@", migrationError);
            return;
        }
    }

    if (currentLibraryVersion < 6) {
        if (![self migrateMainPageContentGroupInManagedObjectContext:moc error:&migrationError]) {
            DDLogError(@"Error during migration: %@", migrationError);
            return;
        }
    }

    if (currentLibraryVersion < 8) {
        NSUserDefaults *ud = [[NSUserDefaults alloc] initWithSuiteName:WMFApplicationGroupIdentifier];
        [ud removeObjectForKey:@"WMFOpenArticleURLKey"];
        [ud removeObjectForKey:@"WMFOpenArticleTitleKey"];
        [ud synchronize];
        [moc wmf_setValue:@(8) forKey:WMFLibraryVersionKey];
        if ([moc hasChanges] && ![moc save:&migrationError]) {
            DDLogError(@"Error saving during migration: %@", migrationError);
            return;
        }
    }

    if (currentLibraryVersion < 9) {
        [self markAllDownloadedArticlesInManagedObjectContextAsNeedingConversionFromMobileview:moc];
        [moc wmf_setValue:@(9) forKey:WMFLibraryVersionKey];
        if ([moc hasChanges] && ![moc save:&migrationError]) {
            DDLogError(@"Error saving during migration: %@", migrationError);
            return;
        }
    }

    if (currentLibraryVersion < 10) {
        [self migrateToStandardUserDefaults];
        [moc wmf_setValue:@(10) forKey:WMFLibraryVersionKey];
        if ([moc hasChanges] && ![moc save:&migrationError]) {
            DDLogError(@"Error saving during migration: %@", migrationError);
            return;
        }
        
        if (![self moveImageControllerCacheFolderWithError:&migrationError]) {
            DDLogError(@"Error saving during migration: %@", migrationError);
            return;
        }
    }

    if (currentLibraryVersion < 11) {
        [MWKLanguageLinkController migratePreferredLanguagesToManagedObjectContext:moc];
        [moc wmf_setValue:@(11) forKey:WMFLibraryVersionKey];
        if ([moc hasChanges] && ![moc save:&migrationError]) {
            DDLogError(@"Error saving during migration: %@", migrationError);
            return;
        }
    }
    
    if (currentLibraryVersion < 12) {
        [[WMFEventLoggingService sharedInstance] migrateShareUsageAndInstallIDToUserDefaults];
        [self migrateToLanguageVariantsForLanguageCodes:@[@"crh", @"gan", @"iu", @"kk", @"ku", @"sr", @"tg", @"uz", @"zh"] inManagedObjectContext:(NSManagedObjectContext *)moc];
        [moc wmf_setValue:@(12) forKey:WMFLibraryVersionKey];
        if ([moc hasChanges] && ![moc save:&migrationError]) {
            DDLogError(@"Error saving during migration: %@", migrationError);
            return;
        }
    }

    // IMPORTANT: When adding a new library version and migration, update WMFCurrentLibraryVersion to the latest version number
}

/// Library updates are separate from Core Data migration and can be used to orchestrate migrations that are more complex than automatic Core Data migration allows.
/// They can also be used to perform migrations when the underlying Core Data model has not changed version but the apps' logic has changed in a way that requires data migration.
- (void)performLibraryUpdates:(dispatch_block_t)completion needsMigrateBlock:(dispatch_block_t)needsMigrateBlock {
    dispatch_block_t combinedCompletion = ^{
        [WMFPermanentCacheController setupCoreDataStack:^(NSManagedObjectContext * _Nullable moc, NSError * _Nullable error) {
            if (error) {
                DDLogError(@"Error during cache controller migration: %@", error);
            }
            WMFPermanentCacheController *permanentCacheController = [[WMFPermanentCacheController alloc] initWithMoc:moc session:self.session configuration:self.configuration preferredLanguageDelegate:self.languageLinkController];
            self.cacheController = permanentCacheController;
            [self startSynchronizingCacheContext:moc];
            if (completion) {
                completion();
            }
        }];
    };
    NSNumber *libraryVersionNumber = [self.viewContext wmf_numberValueForKey:WMFLibraryVersionKey];
    // If the library value doesn't exist, it's a new library and can be set to the latest version
    if (!libraryVersionNumber) {
        [self performInitialLibrarySetup];
        combinedCompletion();
        return;
    }
    NSInteger currentUserLibraryVersion = [libraryVersionNumber integerValue];
    // If the library version is >= the current version, we can skip the migration
    if (currentUserLibraryVersion >= WMFCurrentLibraryVersion) {
        combinedCompletion();
        return;
    }
    
    needsMigrateBlock();
    [self performBackgroundCoreDataOperationOnATemporaryContext:^(NSManagedObjectContext *moc) {
        [self performUpdatesFromLibraryVersion:currentUserLibraryVersion inManagedObjectContext:moc];
        combinedCompletion();
    }];
}

- (void)performInitialLibrarySetup {
    [self.viewContext wmf_fetchOrCreateDefaultReadingList];
    [self.viewContext wmf_setValue:@(WMFCurrentLibraryVersion) forKey:WMFLibraryVersionKey];
    NSError *setupError = nil;
    if (![self.viewContext save:&setupError]) {
        DDLogError(@"Error performing initial library setup: %@", setupError);
    }
}

#if TEST
- (void)performTestLibrarySetup {
    WMFPermanentCacheController *permanentCacheController = [WMFPermanentCacheController testControllerWith:self.containerURL dataStore:self];
    self.cacheController = permanentCacheController;
}
#endif

- (void)markAllDownloadedArticlesInManagedObjectContextAsNeedingConversionFromMobileview:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"isDownloaded == YES && isConversionFromMobileViewNeeded == NO"];
    request.fetchLimit = 500;
    request.propertiesToFetch = @[];
    NSError *fetchError = nil;
    NSArray *downloadedArticles = [moc executeFetchRequest:request error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching downloaded articles: %@", fetchError);
        return;
    }
    while (downloadedArticles.count > 0) {
        @autoreleasepool {
            for (WMFArticle *article in downloadedArticles) {
                article.isConversionFromMobileViewNeeded = YES;
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

- (void)migrateToStandardUserDefaults {
    NSUserDefaults *wmfDefaults = [[NSUserDefaults alloc] initWithSuiteName:WMFApplicationGroupIdentifier];
    if (!wmfDefaults) {
        return;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary<NSString *, id> *wmfDefaultsDictionary = [wmfDefaults dictionaryRepresentation];
    NSArray *keys = [wmfDefaultsDictionary allKeys];
    for (NSString *key in keys) {
        id value = [wmfDefaultsDictionary objectForKey:key];
        [userDefaults setObject:value forKey:key];
        [wmfDefaults removeObjectForKey:value];
    }
}

- (BOOL)moveImageControllerCacheFolderWithError:(NSError **)error {
    
    NSURL *legacyDirectory = [[[NSFileManager defaultManager] wmf_containerURL] URLByAppendingPathComponent:@"Permanent Image Cache" isDirectory:YES];
    NSURL *newDirectory = [[[NSFileManager defaultManager] wmf_containerURL] URLByAppendingPathComponent:@"Permanent Cache" isDirectory:YES];
    
    //move legacy image cache to new non-image path name
    return [[NSFileManager defaultManager] moveItemAtURL:legacyDirectory toURL:newDirectory error:error];
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

#pragma mark - Memory

- (void)didReceiveMemoryWarningWithNotification:(NSNotification *)note {
    [self clearMemoryCache];
}

#pragma mark - Accessors

- (MWKRecentSearchList *)recentSearchList {
    if (!_recentSearchList) {
        _recentSearchList = [[MWKRecentSearchList alloc] initWithDataStore:self];
    }
    return _recentSearchList;
}

- (nullable NSURL*)primarySiteURL {
    return self.languageLinkController.appLanguage.siteURL;
}

#pragma mark - History and Saved Page List

- (void)setupHistoryAndSavedPageLists {
    WMFAssertMainThread(@"History and saved page lists must be setup on the main thread");
    self.savedPageList = [[MWKSavedPageList alloc] initWithDataStore:self];
    self.readingListsController = [[WMFReadingListsController alloc] initWithDataStore:self];
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
    self.articleCache.countLimit = 1000;
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
    NSString *encTitle = [self safeFilenameWithString:url.wmf_titleWithUnderscores];
    return [articlesPath stringByAppendingPathComponent:encTitle];
}

- (NSString *)safeFilenameWithString:(NSString *)str {
    // Escape only % and / with percent style for readability
    NSString *encodedStr = [str stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
    encodedStr = [encodedStr stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];

    return encodedStr;
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

- (BOOL)saveString:(NSString *)string path:(NSString *)path name:(NSString *)name error:(NSError **)error {
    return [self saveData:[string dataUsingEncoding:NSUTF8StringEncoding] toFile:name atPath:path error:error];
}

- (BOOL)saveRecentSearchList:(MWKRecentSearchList *)list error:(NSError **)error {
    NSString *path = self.basePath;
    NSDictionary *export = @{@"entries": [list dataExport]};
    return [self saveDictionary:export path:path name:@"RecentSearches.plist" error:error];
}

- (NSArray *)recentSearchListData {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"RecentSearches.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return dict[@"entries"];
}

#pragma mark - helper methods

- (NSInteger)sitesDirectorySize {
    NSURL *sitesURL = [NSURL fileURLWithPath:[self pathForSites]];
    return (NSInteger)[[NSFileManager defaultManager] sizeOfDirectoryAt:sitesURL];
}

#pragma mark - Deletion

- (NSError *)removeFolderAtBasePath {
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:self.basePath error:&err];
    return err;
}

#pragma mark - Cache

- (void)prefetchArticles {
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.fetchLimit = 1000;
    NSManagedObjectContext *moc = self.viewContext;
    NSArray<WMFArticle *> *prefetchedArticles = [moc executeFetchRequest:request error:nil];
    for (WMFArticle *article in prefetchedArticles) {
        NSString *key = article.key;
        if (!key) {
            continue;
        }
        NSString *variant = article.variant;
        WMFInMemoryURLKey *cacheKey = [[WMFInMemoryURLKey alloc] initWithDatabaseKey:key languageVariantCode:variant];
        [self.articleCache setObject:article forKey:cacheKey];
    }
}

- (void)clearMemoryCache {
    @synchronized(self.articleCache) {
        [self.articleCache removeAllObjects];
    }
}

- (void)clearTemporaryCache {
    [self clearMemoryCache];
    [self.session clearTemporaryCache];
    NSSet<NSString *> *typesToClear = [NSSet setWithObjects:WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, nil];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:typesToClear modifiedSince:[NSDate distantPast] completionHandler:^{}];
}

#pragma mark - Remote Configuration

- (void)updateLocalConfigurationFromRemoteConfigurationWithCompletion:(nullable void (^)(NSError *nullable))completion {
    void (^combinedCompletion)(NSError *) = ^(NSError *error) {
        if (completion) {
            completion(error);
        }
    };

    __block NSError *updateError = nil;
    WMFTaskGroup *taskGroup = [[WMFTaskGroup alloc] init];

    // Site info
    NSURL *siteURL = [NSURL URLWithString:@"//meta.wikimedia.org"]; // Only the host of the URL is needed
    NSURL *URL = [self.configuration mediaWikiAPIURLForURL:siteURL withQueryParameters:WikipediaSiteInfo.defaultRequestParameters];
    [taskGroup enter];
    [self.session getJSONDictionaryFromURL:URL
                                      ignoreCache:YES
                                completionHandler:^(NSDictionary<NSString *, id> *_Nullable siteInfo, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (error) {
                                            updateError = error;
                                            [taskGroup leave];
                                            return;
                                        }
                                        NSDictionary *generalProps = [siteInfo valueForKeyPath:@"query.general"];
                                        NSDictionary *readingListsConfig = generalProps[@"readinglists-config"];
                                        if (self.isLocalConfigUpdateAllowed) {
                                            [self updateReadingListsLimits:readingListsConfig];
                                            self.remoteConfigsThatFailedUpdate &= ~RemoteConfigOptionReadingLists;
                                        } else {
                                            self.remoteConfigsThatFailedUpdate |= RemoteConfigOptionReadingLists;
                                        }
                                        [taskGroup leave];
                                    });
                                }];
    // Remote config
    NSURL *remoteConfigURL = [NSURL URLWithString:@"https://meta.wikimedia.org/static/current/extensions/MobileApp/config/ios.json"];
    [taskGroup enter];
    [self.session getJSONDictionaryFromURL:remoteConfigURL
                                      ignoreCache:YES
                                completionHandler:^(NSDictionary<NSString *, id> *_Nullable remoteConfigurationDictionary, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (error) {
                                            updateError = error;
                                            [taskGroup leave];
                                            return;
                                        }
                                        if (self.isLocalConfigUpdateAllowed) {
                                            [self updateLocalConfigurationFromRemoteConfiguration:remoteConfigurationDictionary];
                                            self.remoteConfigsThatFailedUpdate &= ~RemoteConfigOptionGeneric;
                                        } else {
                                            self.remoteConfigsThatFailedUpdate |= RemoteConfigOptionGeneric;
                                        }
                                        [taskGroup leave];
                                    });
                                }];

    [taskGroup waitInBackgroundWithCompletion:^{
        combinedCompletion(updateError);
    }];
}

- (void)updateLocalConfigurationFromRemoteConfiguration:(NSDictionary *)remoteConfigurationDictionary {
    NSNumber *disableReadingListSyncNumber = remoteConfigurationDictionary[@"disableReadingListSync"];
    BOOL shouldDisableReadingListSync = [disableReadingListSyncNumber boolValue];
    self.readingListsController.isSyncRemotelyEnabled = !shouldDisableReadingListSync;
}

- (void)updateReadingListsLimits:(NSDictionary *)readingListsConfig {
    NSNumber *maxEntriesPerList = readingListsConfig[@"maxEntriesPerList"];
    NSNumber *maxListsPerUser = readingListsConfig[@"maxListsPerUser"];
    self.readingListsController.maxEntriesPerList = maxEntriesPerList;
    self.readingListsController.maxListsPerUser = [maxListsPerUser intValue];
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
    return [self fetchArticleWithKey:URL.wmf_databaseKey variant:URL.wmf_languageVariantCode inManagedObjectContext:moc];
}

- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key variant:(nullable NSString *)variant inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    WMFArticle *article = nil;
    if (moc == _viewContext) { // use ivar to avoid main thread check
        WMFInMemoryURLKey *cacheKey = [[WMFInMemoryURLKey alloc] initWithDatabaseKey:key languageVariantCode:variant];
        article = [self.articleCache objectForKey:cacheKey];
        if (article) {
            return article;
        }
    }
    article = [moc fetchArticleWithKey:key variant:variant];
    if (article && moc == _viewContext) { // use ivar to avoid main thread check
        WMFInMemoryURLKey *cacheKey = [[WMFInMemoryURLKey alloc] initWithDatabaseKey:key languageVariantCode:variant];
        [self.articleCache setObject:article forKey:cacheKey];
    }
    return article;
}

- (nullable WMFArticle *)fetchArticleWithWikidataID:(NSString *)wikidataID {
    return [_viewContext fetchArticleWithWikidataID:wikidataID];
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSString *language = URL.wmf_language;
    NSString *title = URL.wmf_title;
    NSString *key = URL.wmf_databaseKey;
    if (!language || !title || !key) {
        return nil;
    }
    NSString *variant = URL.wmf_languageVariantCode;
    WMFArticle *article = [self fetchArticleWithKey:key variant: variant inManagedObjectContext:moc];
    if (!article) {
        article = [moc createArticleWithKey:key variant:variant];
        article.displayTitleHTML = article.displayTitle;
        if (moc == self.viewContext) {
            WMFInMemoryURLKey *cacheKey = [[WMFInMemoryURLKey alloc] initWithDatabaseKey:key languageVariantCode:variant];
            [self.articleCache setObject:article forKey:cacheKey];
        }
    }
    return article;
}

- (nullable WMFArticle *)fetchArticleWithURL:(NSURL *)URL {
    return [self fetchArticleWithKey:URL.wmf_databaseKey variant:URL.wmf_languageVariantCode];
}

- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key {
    return [self fetchArticleWithKey:key variant:nil];
}

- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key variant:(nullable NSString *)variant {
    WMFAssertMainThread(@"Article fetch must be performed on the main thread.");
    return [self fetchArticleWithKey:key variant:variant inManagedObjectContext:self.viewContext];
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL {
    WMFAssertMainThread(@"Article fetch must be performed on the main thread.");
    return [self fetchOrCreateArticleWithURL:URL inManagedObjectContext:self.viewContext];
}

#pragma mark - WMFAuthenticationManagerDelegate

- (nullable NSURL*)loginSiteURL {
    return self.primarySiteURL;
}

- (void)authenticationManagerDidLogin {
    [self clearMemoryCache];
}

- (void)authenticationManagerDidReset {
    [self clearMemoryCache];
    [self.readingListsController setSyncEnabled:NO shouldDeleteLocalLists:NO shouldDeleteRemoteLists:NO];
}

#pragma mark - WMFSessionAuthenticationDelegate

- (void)attemptReauthentication {
    [self.authenticationManager attemptLoginWithLogoutOnFailureInitiatedBy:LogoutInitiatorServer completion:^{}];
}

- (void)deauthenticate {
    [self.authenticationManager logoutInitiatedBy:LogoutInitiatorServer completion:^{}];
}

#pragma mark - ABTestsManaging

- (void)setupAbTestsControllerWithPersistenceService: (id<ABTestsPersisting>)persistenceService {
    self.abTestsController = [[WMFABTestsController alloc] initWithPersistanceService:persistenceService];
}

@end
