#import "WMFRelatedSectionBlackList.h"
#import "MWKDataStore+WMFDataSources.h"
#import <YapDataBase/YapDatabase.h>
#import "YapDatabaseConnection+WMFExtensions.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import <WMFModel/WMFModel-Swift.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFRelatedSectionBlackListFileName = @"WMFRelatedSectionBlackList";
static NSString *const WMFRelatedSectionBlackListFileExtension = @"plist";

@interface WMFRelatedSectionBlackList ()

@property (nonatomic, strong) id<WMFDataSource> dataSource;
@property (readwrite, weak, nonatomic) MWKDataStore *dataStore;

//Legacy property for migration
@property (nonatomic, strong) NSArray *entries;

@end

@implementation WMFRelatedSectionBlackList

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        self.dataSource = [self.dataStore blackListDataSource];
        [self migrateLegacyDataIfNeeded];
    }
    return self;
}

#pragma mark - Legacy Migration

- (void)migrateLegacyDataIfNeeded {
    if ([[NSUserDefaults wmf_userDefaults] wmf_didMigrateBlackList]) {
        return;
    }

    WMFRelatedSectionBlackList *blackList = [[self class] loadFromDisk];
    NSArray<NSURL *> *entries = [blackList.entries wmf_mapAndRejectNil:^id _Nullable(id _Nonnull obj) {
        if ([obj isKindOfClass:[NSURL class]]) {
            return obj;
        } else if ([obj isKindOfClass:[MWKTitle class]]) {
            return [(MWKTitle *)obj URL];
        } else {
            return nil;
        }
    }];

    if ([entries count] > 0) {
        [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
            NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[entries count]];
            [entries enumerateObjectsUsingBlock:^(NSURL *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                MWKHistoryEntry *entry = nil;
                MWKHistoryEntry *existing = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:obj] inCollection:[MWKHistoryEntry databaseCollectionName]];
                if (existing) {
                    entry = [existing copy];
                } else {
                    entry = [[MWKHistoryEntry alloc] initWithURL:obj];
                }
                entry.blackListed = YES;

                [transaction setObject:entry forKey:[entry databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
                [urls addObject:[entry databaseKey]];
            }];
            return urls;
        }];

        [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateBlackList:YES];
    }
}

+ (NSUInteger)modelVersion {
    return 1;
}

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
    if ([key isEqualToString:WMF_SAFE_KEYPATH(self, entries)] && modelVersion == 0) {
        NSArray *titles = [super decodeValueForKey:WMF_SAFE_KEYPATH(self, entries) withCoder:coder modelVersion:0];
        return [titles wmf_mapAndRejectNil:^id(NSURL *obj) {

            if ([obj isKindOfClass:[NSURL class]]) {
                return obj;
            } else if ([obj isKindOfClass:[MWKTitle class]]) {
                return [(MWKTitle *)obj URL];
            } else {
                return nil;
            }
        }];
    } else {
        return [super decodeValueForKey:key withCoder:coder modelVersion:modelVersion];
    }
}

+ (NSURL *)fileURL {
    return [NSURL fileURLWithPath:[[documentsDirectory() stringByAppendingPathComponent:WMFRelatedSectionBlackListFileName] stringByAppendingPathExtension:WMFRelatedSectionBlackListFileExtension]];
}

+ (instancetype)loadFromDisk {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[[self fileURL] path]];
}

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems {
    return [self.dataSource numberOfItems];
}

- (nullable MWKHistoryEntry *)entryForURL:(NSURL *)url {
    return [self.dataSource readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        if (entry.isBlackListed) {
            return entry;
        } else {
            return nil;
        }
    }];
}

- (nullable MWKHistoryEntry *)mostRecentEntry {
    return [self.dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
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
                                      if (object.isBlackListed) {
                                          block(object, stop);
                                      }
                                  }];
    }];
}

#pragma mark - Update Methods

- (MWKHistoryEntry *)addBlackListArticleURL:(NSURL *)url {
    NSParameterAssert(url);
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
        entry.blackListed = YES;

        [transaction setObject:entry forKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        return @[[MWKHistoryEntry databaseKeyForURL:url]];
    }];

    return entry;
}

- (void)removeBlackListArticleURL:(NSURL *)url {
    if ([[url wmf_title] length] == 0) {
        return;
    }
    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        entry.blackListed = NO;
        [transaction setObject:entry forKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        return @[[MWKHistoryEntry databaseKeyForURL:url]];
    }];
}

- (void)removeAllEntries {
    [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray<NSString *> *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithCapacity:[self numberOfItems]];
        [transaction enumerateKeysAndObjectsInCollection:[MWKHistoryEntry databaseCollectionName]
                                              usingBlock:^(NSString *_Nonnull key, MWKHistoryEntry *_Nonnull object, BOOL *_Nonnull stop) {
                                                  if (object.isBlackListed) {
                                                      [keys addObject:key];
                                                  }
                                              }];
        [keys enumerateObjectsUsingBlock:^(NSString *_Nonnull key, NSUInteger idx, BOOL *_Nonnull stop) {
            MWKHistoryEntry *entry = [[transaction objectForKey:key inCollection:[MWKHistoryEntry databaseCollectionName]] copy];
            entry.blackListed = NO;
            [transaction setObject:entry forKey:key inCollection:[MWKHistoryEntry databaseCollectionName]];
        }];
        return keys;
    }];
}

- (BOOL)articleURLIsBlackListed:(NSURL *)url {
    if ([url.wmf_title length] == 0) {
        return NO;
    }
    return [self entryForURL:url].isBlackListed;
}

@end

NS_ASSUME_NONNULL_END
