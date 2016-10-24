#import "MWKHistoryList.h"
#import "MWKDataStore+WMFDataSources.h"
#import <YapDataBase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import "NSDateFormatter+WMFExtensions.h"
#import <WMFModel/WMFModel-Swift.h>

#define MAX_HISTORY_ENTRIES 100

NS_ASSUME_NONNULL_BEGIN

@interface MWKHistoryList ()

@property (nonatomic, strong) id<WMFDataSource> dataSource;

@property (readwrite, weak, nonatomic) MWKDataStore *dataStore;

@end

@implementation MWKHistoryList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        self.dataSource = [self.dataStore historyDataSource];
        [self migrateLegacyDataIfNeeded];
    }
    return self;
}

#pragma mark - Legacy Migration

- (void)migrateLegacyDataIfNeeded {
    if ([[NSUserDefaults wmf_userDefaults] wmf_didMigrateHistoryList]) {
        return;
    }

    NSArray<MWKHistoryEntry *> *entries = [[self.dataStore historyListData] wmf_mapAndRejectNil:^id(id obj) {
        @try {
            return [[MWKHistoryEntry alloc] initWithDict:obj];
        } @catch (NSException *exception) {
            return nil;
        }
    }];

    if ([entries count] > 0) {
        [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
            NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[entries count]];
            [entries enumerateObjectsUsingBlock:^(MWKHistoryEntry *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                MWKHistoryEntry *existing = [transaction objectForKey:[obj databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
                if (existing) {
                    obj.dateSaved = existing.dateSaved;
                    obj.blackListed = existing.isBlackListed;
                }

                [transaction setObject:obj forKey:[obj databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
                [urls addObject:[obj databaseKey]];
            }];
            return urls;
        }];

        [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateHistoryList:YES];
    }
}

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems {
    return [self.dataSource numberOfItems];
}

- (nullable MWKHistoryEntry *)mostRecentEntry {
    return [self.dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (nullable MWKHistoryEntry *)entryForURL:(NSURL *)url {
    return [self.dataSource readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        if (entry.dateViewed != nil) {
            return entry;
        } else {
            return nil;
        }
    }];
}

- (void)enumerateItemsWithBlock:(void (^)(MWKHistoryEntry *_Nonnull entry, BOOL *stop))block {
    NSParameterAssert(block);
    if (!block) {
        return;
    }
    [self.dataSource readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        if ([view numberOfItemsInAllGroups] == 0) {
            return;
        }
        [view enumerateKeysAndObjectsInGroup:[[view allGroups] firstObject]
                                  usingBlock:^(NSString *_Nonnull collection, NSString *_Nonnull key, MWKHistoryEntry *_Nonnull object, NSUInteger index, BOOL *_Nonnull stop) {
                                      if (object.dateViewed) {
                                          block(object, stop);
                                      }
                                  }];
    }];
}

#pragma mark - Update Methods

- (MWKHistoryEntry *)addEntry:(MWKHistoryEntry *)entry {
    NSParameterAssert(entry.url);
    if ([entry.url wmf_isNonStandardURL]) {
        return nil;
    }
    if ([entry.url.wmf_title length] == 0) {
        return nil;
    }

    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        [transaction setObject:entry forKey:[entry databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
        return @[[entry databaseKey]];
    }];

    return entry;
}

- (MWKHistoryEntry *)addPageToHistoryWithURL:(NSURL *)url {
    NSParameterAssert(url);
    if (!url) {
        return nil;
    }

    if ([url wmf_isNonStandardURL]) {
        return nil;
    }
    if ([url.wmf_title length] == 0) {
        return nil;
    }

    __block MWKHistoryEntry *entry = nil;

    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        if (!entry) {
            entry = [[MWKHistoryEntry alloc] initWithURL:url];
        } else {
            entry = [entry copy];
        }
        entry.dateViewed = [NSDate date];

        [transaction setObject:entry forKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        return @[[MWKHistoryEntry databaseKeyForURL:url]];
    }];

    return entry;
}

- (void)setFragment:(nullable NSString *)fragment scrollPosition:(CGFloat)scrollposition onPageInHistoryWithURL:(NSURL *)url {
    if ([url.wmf_title length] == 0) {
        return;
    }

    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        if (entry) {
            entry.fragment = fragment;
            entry.scrollPosition = scrollposition;
            [transaction setObject:entry forKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        }
        return @[[MWKHistoryEntry databaseKeyForURL:url]];
    }];
}

- (void)setInTheNewsNotificationDate:(NSDate *)date forArticlesWithURLs:(NSArray<NSURL *> *)articleURLs {
    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        NSMutableArray<NSString *> *databaseKeys = [NSMutableArray arrayWithCapacity:articleURLs.count];
        for (NSURL *articleURL in articleURLs) {
            NSString *databaseKey = [MWKHistoryEntry databaseKeyForURL:articleURL];
            MWKHistoryEntry *entry = [transaction objectForKey:databaseKey inCollection:[MWKHistoryEntry databaseCollectionName]];
            if (entry) {
                entry.inTheNewsNotificationDate = date;
                [transaction setObject:entry forKey:databaseKey inCollection:[MWKHistoryEntry databaseCollectionName]];
            }
        }
        return databaseKeys;
    }];
}

- (void)setSignificantlyViewedOnPageInHistoryWithURL:(NSURL *)url {
    if ([url.wmf_title length] == 0) {
        return;
    }
    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        if (entry) {
            entry.titleWasSignificantlyViewed = YES;
            [transaction setObject:entry forKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        }
        return @[[MWKHistoryEntry databaseKeyForURL:url]];
    }];
}

- (void)removeEntryWithURL:(NSURL *)url {
    if ([[url wmf_title] length] == 0) {
        return;
    }
    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        entry.dateViewed = nil;
        [transaction setObject:entry forKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        return @[[MWKHistoryEntry databaseKeyForURL:url]];
    }];
}

- (void)removeAllEntries {
    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray<NSString *> *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithCapacity:[self numberOfItems]];
        [transaction enumerateKeysAndObjectsInCollection:[MWKHistoryEntry databaseCollectionName]
                                              usingBlock:^(NSString *_Nonnull key, MWKHistoryEntry *_Nonnull object, BOOL *_Nonnull stop) {
                                                  if (object.dateViewed != nil) {
                                                      [keys addObject:key];
                                                  }
                                              }];
        [keys enumerateObjectsUsingBlock:^(NSString *_Nonnull key, NSUInteger idx, BOOL *_Nonnull stop) {
            MWKHistoryEntry *entry = [[transaction objectForKey:key inCollection:[MWKHistoryEntry databaseCollectionName]] copy];
            entry.dateViewed = nil;
            [transaction setObject:entry forKey:key inCollection:[MWKHistoryEntry databaseCollectionName]];
        }];
        return keys;
    }];
}

@end

NS_ASSUME_NONNULL_END
