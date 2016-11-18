#import "MWKSavedPageList.h"
#import "MWKDataStore+WMFDataSources.h"
#import <YapDataBase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import <WMFModel/WMFModel-Swift.h>

//Legacy
#import "MWKSavedPageListDataExportConstants.h"
#import "MWKSavedPageEntry.h"
NSString *const MWKSavedPageExportedEntriesKey = @"entries";
NSString *const MWKSavedPageExportedSchemaVersionKey = @"schemaVersion";

@interface MWKSavedPageList ()

@property (nonatomic, strong) id<WMFDataSource> dataSource;

@property (readwrite, weak, nonatomic) MWKDataStore *dataStore;

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
        self.dataSource = [self.dataStore savedDataSource];
        [self migrateLegacyDataIfNeeded];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)applicationDidBecomeActive:(NSNotification *)note {
    NSURL *containerURL = [[NSFileManager defaultManager] wmf_containerURL];
    NSString *filename = @"Saved.articles";
    NSURL *savedArticlesURL = [containerURL URLByAppendingPathComponent:filename isDirectory:NO];
    if (!savedArticlesURL) {
        return;
    }
    
    NSData *savedArticlesData = [NSData dataWithContentsOfURL:savedArticlesURL];
    if (!savedArticlesData) {
        return;
    }
    
    NSArray<NSString *> *articlesToSave = [NSKeyedUnarchiver unarchiveObjectWithData:savedArticlesData];
    if (articlesToSave.count == 0) {
        return;
    }
    
    for (NSString *articleToSave in articlesToSave) {
        NSURL *articleURL = [NSURL URLWithString:articleToSave];
        if (!articleURL) {
            continue;
        }
        [self addSavedPageWithURL:articleURL];
    }
   
    [[NSFileManager defaultManager] removeItemAtURL:savedArticlesURL error:nil];
}

#pragma mark - Legacy Migration

- (MWKHistoryEntry *)historyEntryWithSavedPageEntry:(MWKSavedPageEntry *)entry {
    MWKHistoryEntry *history = [[MWKHistoryEntry alloc] initWithURL:entry.url];
    history.dateSaved = entry.date;
    return history;
}

- (void)migrateLegacyDataIfNeeded {
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

    if ([entries count] > 0) {
        [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray<NSString *> *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
            NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[entries count]];
            [entries enumerateObjectsUsingBlock:^(MWKSavedPageEntry *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                if (obj.url.wmf_title.length == 0) {
                    //HACK: Added check from pre-existing logic. Apparently there was a time when this URL could be bad. Copying here to keep exisitng functionality
                    return;
                }
                MWKHistoryEntry *history = [self historyEntryWithSavedPageEntry:obj];
                MWKHistoryEntry *existing = [transaction objectForKey:[history databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
                if (existing) {
                    existing.dateSaved = history.dateSaved;
                    history = existing;
                }
                [transaction setObject:history forKey:[history databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
                [urls addObject:[history databaseKey]];
            }];
            return urls;
        }];

        [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateSavedPageList:YES];
    }
}

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems {
    return [self.dataSource numberOfItems];
}

- (nullable MWKHistoryEntry *)mostRecentEntry {
    return (MWKHistoryEntry*)[self.dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (nullable MWKHistoryEntry *)entryForURL:(NSURL *)url {
    return [self.dataSource readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        if (entry.dateSaved != nil) {
            return entry;
        } else {
            return nil;
        }
    }];
}

- (void)enumerateItemsWithBlock:(void (^)(MWKHistoryEntry *_Nonnull entry, BOOL *stop))block {
    if (!block) {
        return;
    }
    [self.dataSource readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        if ([view numberOfItemsInAllGroups] == 0) {
            return;
        }
        [view enumerateKeysAndObjectsInGroup:[[view allGroups] firstObject]
                                  usingBlock:^(NSString *_Nonnull collection, NSString *_Nonnull key, MWKHistoryEntry *_Nonnull object, NSUInteger index, BOOL *_Nonnull stop) {
                                      if (object.dateSaved) {
                                          block(object, stop);
                                      }
                                  }];
    }];
}

- (BOOL)isSaved:(NSURL *)url {
    if ([url.wmf_title length] == 0) {
        return NO;
    }
    return [self entryForURL:url].dateSaved != nil;
}

#pragma mark - Update Methods

- (void)addEntry:(MWKHistoryEntry *)entry {
    NSParameterAssert(entry.url);
    if ([entry.url wmf_isNonStandardURL]) {
        return;
    }
    if ([entry.url.wmf_title length] == 0) {
        return;
    }

    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        [transaction setObject:entry forKey:[entry databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
        return @[[entry databaseKey]];
    }];
}
- (void)toggleSavedPageForURL:(NSURL *)url {
    if ([self isSaved:url]) {
        [self removeEntryWithURL:url];
    } else {
        [self addSavedPageWithURL:url];
    }
}

- (void)addSavedPageWithURL:(NSURL *)url {
    if ([url wmf_isNonStandardURL]) {
        return;
    }
    if ([url.wmf_title length] == 0) {
        return;
    }

    __block MWKHistoryEntry *entry = nil;

    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray<NSString *> *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        if (!entry) {
            entry = [[MWKHistoryEntry alloc] initWithURL:url];
        }
        if (!entry.dateSaved) {
            entry.dateSaved = [NSDate date];
        }

        [transaction setObject:entry forKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];

        return @[[entry databaseKey]];
    }];
}

- (void)removeEntryWithURL:(NSURL *)url {
    if ([url.wmf_title length] == 0) {
        return;
    }
    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray<NSString *> *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        entry.dateSaved = nil;
        [transaction setObject:entry forKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        return @[[MWKHistoryEntry databaseKeyForURL:url]];
    }];
}

- (void)removeAllEntries {
    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray<NSString *> *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithCapacity:[self numberOfItems]];
        [transaction enumerateKeysAndObjectsInCollection:[MWKHistoryEntry databaseCollectionName]
                                              usingBlock:^(NSString *_Nonnull key, MWKHistoryEntry *_Nonnull object, BOOL *_Nonnull stop) {
                                                  if (object.dateSaved != nil) {
                                                      [keys addObject:key];
                                                  }
                                              }];
        [keys enumerateObjectsUsingBlock:^(NSString *_Nonnull key, NSUInteger idx, BOOL *_Nonnull stop) {
            MWKHistoryEntry *entry = [[transaction objectForKey:key inCollection:[MWKHistoryEntry databaseCollectionName]] copy];
            entry.dateSaved = nil;
            [transaction setObject:entry forKey:key inCollection:[MWKHistoryEntry databaseCollectionName]];
        }];
        return keys;
    }];
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
