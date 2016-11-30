#import "MWKSavedPageList.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import <WMFModel/WMFModel-Swift.h>

//Legacy
#import "MWKSavedPageListDataExportConstants.h"
#import "MWKSavedPageEntry.h"
NSString *const MWKSavedPageExportedEntriesKey = @"entries";
NSString *const MWKSavedPageExportedSchemaVersionKey = @"schemaVersion";

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
        [self migrateLegacyDataIfNeeded];
    }
    return self;
}

#pragma mark - Legacy Migration

- (void)migrateLegacyDataIfNeeded {
    NSAssert([NSThread isMainThread], @"Legacy migration must happen on the main thread");

    if ([[NSUserDefaults wmf_userDefaults] wmf_didMigrateSavedPageList]) {
        return;
    }

    NSArray<MWKSavedPageEntry *> *entries =
        [[MWKSavedPageList savedEntryDataFromExportedData:[self.dataStore savedPageListData]] wmf_mapAndRejectNil:^id(id obj) {
            @try {
                return [[MWKSavedPageEntry alloc] initWithDict:obj];
            } @catch (NSException *e) {
                return nil;
            }
        }];

    if ([entries count] == 0) {
        [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateSavedPageList:YES];
        return;
    }

    [entries enumerateObjectsUsingBlock:^(MWKSavedPageEntry *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if (obj.url.wmf_title.length == 0) {
            //HACK: Added check from pre-existing logic. Apparently there was a time when this URL could be bad. Copying here to keep exisitng functionality
            return;
        }

        WMFArticle *article = [self.dataStore fetchOrCreateArticleForURL:obj.url];
        article.savedDate = obj.date;
    }];

    NSError *migrationError = nil;
    if (![self.dataStore save:&migrationError]) {
        DDLogError(@"Error migrating legacy saved pages: %@", migrationError);
        return;
    }

    [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateSavedPageList:YES];
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
    NSString *key = [url wmf_articleDatabaseKey];
    if (!key) {
        return nil;
    }
    WMFArticle *article = [self.dataStore fetchArticleForKey:key];
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

- (void)addSavedPageWithURL:(NSURL *)url {
    WMFArticle *article = [self.dataStore fetchOrCreateArticleForURL:url];
    article.savedDate = [NSDate date];
    [self.dataStore save:nil];
}

- (void)removeEntryWithURL:(NSURL *)url {
    WMFArticle *article = [self.dataStore fetchArticleForURL:url];
    if (!article) {
        return;
    }
    article.savedDate = nil;
    [self.dataStore save:nil];
}

- (void)removeAllEntries {
    [self enumerateItemsWithBlock:^(WMFArticle *_Nonnull entry, BOOL *_Nonnull stop) {
        entry.savedDate = nil;
    }];
    [self.dataStore save:nil];
}

#pragma mark - Legacy Schema Migration

+ (NSArray<NSDictionary *> *)savedEntryDataFromExportedData:(NSDictionary *)savedPageListData {
    NSNumber *schemaVersionValue = savedPageListData[MWKSavedPageExportedSchemaVersionKey];
    MWKSavedPageListSchemaVersion schemaVersion = MWKSavedPageListSchemaVersionUnknown;
    if (schemaVersionValue) {
        schemaVersion = schemaVersionValue.unsignedIntegerValue;
    }
    switch (schemaVersion) {
        case MWKSavedPageListSchemaVersionCurrent:
            return savedPageListData[MWKSavedPageExportedEntriesKey];
        case MWKSavedPageListSchemaVersionUnknown:
            return [MWKSavedPageList savedEntryDataFromListWithUnknownSchema:savedPageListData];
    }
}

+ (NSArray<NSDictionary *> *)savedEntryDataFromListWithUnknownSchema:(NSDictionary *)data {
    return [data[MWKSavedPageExportedEntriesKey] wmf_reverseArray];
}

@end
