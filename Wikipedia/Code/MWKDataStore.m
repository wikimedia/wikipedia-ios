#import <WMF/WMF-Swift.h>
#include <notify.h>
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
static const NSInteger WMFCurrentLibraryVersion = 10;

NSString *const MWKDataStoreValidImageSitePrefix = @"//upload.wikimedia.org/";

NSString *MWKCreateImageURLWithPath(NSString *path) {
    return [MWKDataStoreValidImageSitePrefix stringByAppendingString:path];
}

@interface MWKDataStore () {
    dispatch_semaphore_t _handleCrossProcessChangesSemaphore;
}

@property (readwrite, strong, nonatomic) MWKSavedPageList *savedPageList;
@property (readwrite, strong, nonatomic) MWKRecentSearchList *recentSearchList;

@property (nonatomic, strong) WMFReadingListsController *readingListsController;
@property (nonatomic, strong) WMFExploreFeedContentController *feedContentController;
@property (nonatomic, strong) WikidataDescriptionEditingController *wikidataDescriptionEditingController;
@property (nonatomic, strong) RemoteNotificationsController *remoteNotificationsController;
@property (nonatomic, strong) WMFArticleSummaryController *articleSummaryController;

@property (nonatomic, strong) MobileviewToMobileHTMLConverter *mobileviewConverter;

@property (readwrite, copy, nonatomic) NSString *basePath;
@property (readwrite, strong, nonatomic) NSCache *articleCache;

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *viewContext;
@property (nonatomic, strong) NSManagedObjectContext *feedImportContext;

@property (nonatomic, strong) NSString *crossProcessNotificationChannelName;
@property (nonatomic) int crossProcessNotificationToken;

@property (nonatomic, strong) NSURL *containerURL;

@property (readwrite, nonatomic) RemoteConfigOption remoteConfigsThatFailedUpdate;

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
        _handleCrossProcessChangesSemaphore = dispatch_semaphore_create(1);
        self.containerURL = containerURL;
        self.basePath = [self.containerURL URLByAppendingPathComponent:@"Data" isDirectory:YES].path;
        [self setupLegacyDataStore];
        NSDictionary *infoDictionary = [self loadSharedInfoDictionaryWithContainerURL:containerURL];
        self.crossProcessNotificationChannelName = infoDictionary[@"CrossProcessNotificiationChannelName"];
        [self setupCrossProcessCoreDataNotifier];
        [self setupCoreDataStackWithContainerURL:containerURL];
        [self setupHistoryAndSavedPageLists];
        self.feedContentController = [[WMFExploreFeedContentController alloc] init];
        self.feedContentController.dataStore = self;
        self.feedContentController.siteURLs = [[MWKLanguageLinkController sharedInstance] preferredSiteURLs];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarningWithNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        self.wikidataDescriptionEditingController = [[WikidataDescriptionEditingController alloc] initWithSession:[WMFSession shared] configuration:[WMFConfiguration current]];
        self.remoteNotificationsController = [[RemoteNotificationsController alloc] initWithSession:[WMFSession shared] configuration:[WMFConfiguration current]];
        WMFArticleSummaryFetcher *fetcher = [[WMFArticleSummaryFetcher alloc] initWithSession:[WMFSession shared] configuration:[WMFConfiguration current]];
        self.articleSummaryController = [[WMFArticleSummaryController alloc] initWithFetcher:fetcher dataStore:self];
        self.mobileviewConverter = [[MobileviewToMobileHTMLConverter alloc] init];
    }
    return self;
}

- (NSDictionary *)loadSharedInfoDictionaryWithContainerURL:(NSURL *)containerURL {
    NSURL *infoDictionaryURL = [containerURL URLByAppendingPathComponent:@"Wikipedia.info" isDirectory:NO];
    NSData *infoDictionaryData = [NSData dataWithContentsOfURL:infoDictionaryURL];
    NSDictionary *infoDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:infoDictionaryData];
    if (!infoDictionary[@"CrossProcessNotificiationChannelName"]) {
        NSString *channelName = [NSString stringWithFormat:@"org.wikimedia.wikipedia.cd-cpn-%@", [NSUUID new].UUIDString].lowercaseString;
        infoDictionary = @{@"CrossProcessNotificiationChannelName": channelName};
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

- (void)handleCrossProcessChangesFromContextDidSaveNotification:(NSNotification *)note {
    dispatch_semaphore_wait(_handleCrossProcessChangesSemaphore, DISPATCH_TIME_FOREVER);
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
    dispatch_semaphore_signal(_handleCrossProcessChangesSemaphore);
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
    [self handleCrossProcessChangesFromContextDidSaveNotification:note];
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
    if (currentLibraryVersion < 1) {
        if ([self migrateContentGroupsToPreviewContentInManagedObjectContext:moc error:nil]) {
            [moc wmf_setValue:@(1) forKey:WMFLibraryVersionKey];
            if ([moc hasChanges] && ![moc save:&migrationError]) {
                DDLogError(@"Error saving during migration: %@", migrationError);
                return;
            }
        } else {
            return;
        }
    }

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

    if (currentLibraryVersion < 7) {
        NSError *fileProtectionError = nil;
        if ([self.containerURL setResourceValue:NSURLFileProtectionCompleteUntilFirstUserAuthentication forKey:NSURLFileProtectionKey error:&fileProtectionError]) {
            [moc wmf_setValue:@(7) forKey:WMFLibraryVersionKey];
            NSError *migrationSaveError = nil;
            if ([moc hasChanges] && ![moc save:&migrationSaveError]) {
                DDLogError(@"Error saving during migration: %@", migrationSaveError);
                return;
            }
        } else {
            DDLogError(@"Error enabling file protection: %@", fileProtectionError);
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
        
        [self moveImageControllerCacheFolderWithError:&migrationError];
        if (migrationError) {
            DDLogError(@"Error saving during migration: %@", migrationError);
            return;
        }
    }

    // IMPORTANT: When adding a new library version and migration, update WMFCurrentLibraryVersion to the latest version number
}

/// Library updates are separate from Core Data migration and can be used to orchestrate migrations that are more complex than automatic Core Data migration allows.
/// They can also be used to perform migrations when the underlying Core Data model has not changed version but the apps' logic has changed in a way that requires data migration.
- (void)performLibraryUpdates:(dispatch_block_t)completion {
    NSNumber *libraryVersionNumber = [self.viewContext wmf_numberValueForKey:WMFLibraryVersionKey];
    // If the library value doesn't exist, it's a new library and can be set to the latest version
    if (!libraryVersionNumber) {
        [self performInitialLibrarySetup];
        if (completion) {
            completion();
        }
        return;
    }
    NSInteger currentUserLibraryVersion = [libraryVersionNumber integerValue];
    // If the library version is >= the current version, we can skip the migration
    if (currentUserLibraryVersion >= WMFCurrentLibraryVersion) {
        if (completion) {
            completion();
        }
        return;
    }
    [self performBackgroundCoreDataOperationOnATemporaryContext:^(NSManagedObjectContext *moc) {
        dispatch_block_t done = ^{
            dispatch_async(dispatch_get_main_queue(), completion);
        };
        [self performUpdatesFromLibraryVersion:currentUserLibraryVersion inManagedObjectContext:moc];
        done();
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

- (void)moveImageControllerCacheFolderWithError: (NSError **)error {
    
    NSURL *legacyDirectory = [[[NSFileManager defaultManager] wmf_containerURL] URLByAppendingPathComponent:@"Permanent Image Cache" isDirectory:YES];
    NSURL *newDirectory = [[[NSFileManager defaultManager] wmf_containerURL] URLByAppendingPathComponent:@"Permanent Cache" isDirectory:YES];
    
    //move legacy image cache to new non-image path name
    [[NSFileManager defaultManager] moveItemAtURL:legacyDirectory toURL:newDirectory error:error];
}

- (BOOL)migrateContentGroupsToPreviewContentInManagedObjectContext:(NSManagedObjectContext *)moc error:(NSError **)error {
    NSFetchRequest *request = [WMFContentGroup fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"content != NULL"];
    request.fetchLimit = 500;
    NSError *fetchError = nil;
    NSArray *contentGroups = [moc executeFetchRequest:request error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        if (error) {
            *error = fetchError;
        }
        return false;
    }

    while (contentGroups.count > 0) {
        @autoreleasepool {
            NSMutableArray *toDelete = [NSMutableArray arrayWithCapacity:1];
            for (WMFContentGroup *contentGroup in contentGroups) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                NSArray *content = contentGroup.content;
                if (!content) {
                    continue;
                }
                contentGroup.fullContentObject = content;
                contentGroup.featuredContentIdentifier = contentGroup.articleURLString;
                [contentGroup updateContentPreviewWithContent:content];
                contentGroup.content = nil;
#pragma clang diagnostic pop
                if (contentGroup.contentPreview == nil) {
                    [toDelete addObject:contentGroup];
                }
            }
            for (WMFContentGroup *group in toDelete) {
                [moc deleteObject:group];
            }

            if ([moc hasChanges]) {
                NSError *saveError = nil;
                [moc save:&saveError];
                if (saveError) {
                    DDLogError(@"Error saving downloaded articles: %@", fetchError);
                    if (error) {
                        *error = saveError;
                    }
                    return false;
                }
                [moc reset];
            }
        }

        contentGroups = [moc executeFetchRequest:request error:&fetchError];
        if (fetchError) {
            DDLogError(@"Error fetching content groups: %@", fetchError);
            if (error) {
                *error = fetchError;
            }
            return false;
        }
    }
    return true;
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
        [self.articleCache setObject:article forKey:key];
    }
}

- (void)clearMemoryCache {
    @synchronized(self.articleCache) {
        [self.articleCache removeAllObjects];
    }
}

- (void)clearTemporaryCache {
    [self clearMemoryCache];
    [WMFSession clearTemporaryCache];
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
    NSURLComponents *components = [[WMFConfiguration current] mediaWikiAPIURLComponentsForHost:@"meta.wikimedia.org" withQueryParameters:WikipediaSiteInfo.defaultRequestParameters];
    [taskGroup enter];
    [[WMFSession shared] getJSONDictionaryFromURL:components.URL
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
    [[WMFSession shared] getJSONDictionaryFromURL:remoteConfigURL
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
    return [self fetchArticleWithKey:[URL wmf_databaseKey] inManagedObjectContext:moc];
}

- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    WMFArticle *article = nil;
    if (moc == _viewContext) { // use ivar to avoid main thread check
        article = [self.articleCache objectForKey:key];
        if (article) {
            return article;
        }
    }
    article = [moc fetchArticleWithKey:key];
    if (article && moc == _viewContext) { // use ivar to avoid main thread check
        [self.articleCache setObject:article forKey:key];
    }
    return article;
}

- (nullable WMFArticle *)fetchArticleWithWikidataID:(NSString *)wikidataID {
    return [_viewContext fetchArticleWithWikidataID:wikidataID];
}

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSString *language = URL.wmf_language;
    NSString *title = URL.wmf_title;
    NSString *key = [URL wmf_databaseKey];
    if (!language || !title || !key) {
        return nil;
    }
    WMFArticle *article = [self fetchArticleWithKey:key inManagedObjectContext:moc];
    if (!article) {
        article = [moc createArticleWithKey:key];
        article.displayTitleHTML = article.displayTitle;
        if (moc == self.viewContext) {
            [self.articleCache setObject:article forKey:key];
        }
    }
    return article;
}

- (nullable WMFArticle *)fetchArticleWithURL:(NSURL *)URL {
    return [self fetchArticleWithKey:[URL wmf_databaseKey]];
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
