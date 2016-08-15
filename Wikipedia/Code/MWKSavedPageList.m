#import "MWKSavedPageList.h"
#import "MWKDataStore.h"
#import "MWKSavedPageListDataExportConstants.h"
#import "MWKList+Subclass.h"
#import "Wikipedia-Swift.h"

NSString *const MWKSavedPageListDidSaveNotification =
    @"MWKSavedPageListDidSaveNotification";
NSString *const MWKSavedPageListDidUnsaveNotification =
    @"MWKSavedPageListDidUnsaveNotification";

NSString *const MWKURLKey = @"MWKURLKey";

NSString *const MWKSavedPageExportedEntriesKey = @"entries";
NSString *const MWKSavedPageExportedSchemaVersionKey = @"schemaVersion";

@interface MWKSavedPageList ()

@property(readwrite, weak, nonatomic) MWKDataStore *dataStore;

@end

@implementation MWKSavedPageList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
  NSArray *entries = [[MWKSavedPageList
      savedEntryDataFromExportedData:[dataStore savedPageListData]]
      wmf_mapAndRejectNil:^id(id obj) {
        @try {
          return [[MWKSavedPageEntry alloc] initWithDict:obj];
        } @catch (NSException *e) {
          NSLog(@"Encountered exception while reading entry %@: %@", e, obj);
          return nil;
        }
      }];

  self = [super initWithEntries:entries];
  if (self) {
    self.dataStore = dataStore;
  }
  return self;
}

- (void)importEntries:(NSArray *)entries {
  NSArray<MWKSavedPageEntry *> *validEntries =
      [entries bk_reject:^BOOL(MWKSavedPageEntry *entry) {
        return entry.url.wmf_title.length == 0;
      }];
  NSArray<MWKSavedPageEntry *> *uniqueValidEntries =
      [[NSOrderedSet orderedSetWithArray:validEntries] array];
  [super importEntries:uniqueValidEntries];
}

#pragma mark - Entry Access

- (MWKSavedPageEntry *)mostRecentEntry {
  return [self.entries firstObject];
}

- (MWKSavedPageEntry *__nullable)entryForListIndex:(NSURL *)url {
  if ([url.wmf_title length] == 0) {
    return nil;
  }
  return [super entryForListIndex:url];
}

- (BOOL)isSaved:(NSURL *)url {
  if ([url.wmf_title length] == 0) {
    return NO;
  }
  return [self containsEntryForListIndex:url];
}

#pragma mark - Update Methods

- (void)toggleSavedPageForURL:(NSURL *)url {
  if ([self isSaved:url]) {
    [self removeEntryWithListIndex:url];
  } else {
    [self addSavedPageWithURL:url];
  }
}

- (void)addSavedPageWithURL:(NSURL *)url {
  if ([url.wmf_title length] == 0) {
    return;
  }
  [self addEntry:[[MWKSavedPageEntry alloc] initWithURL:url]];
}

- (void)addEntry:(MWKSavedPageEntry *)entry {
  if ([self isSaved:entry.url]) {
    return;
  }
  [self insertEntry:entry atIndex:0];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:MWKSavedPageListDidSaveNotification
                    object:self
                  userInfo:@{MWKURLKey : entry.url}];
}

- (void)cleanupRemovedEntries:(NSArray<MWKSavedPageEntry *> *)entries {
  if (entries == nil || entries.count == 0) {
    return;
  }
  MWKHistoryList *historyList = self.dataStore.userDataStore.historyList;
  NSSet *historyTitles = [NSSet
      setWithArray:[historyList.entries
                       valueForKey:WMF_SAFE_KEYPATH([MWKHistoryEntry new],
                                                    url)]];
  NSMutableSet *removedTitles = [NSMutableSet
      setWithArray:[entries valueForKey:WMF_SAFE_KEYPATH(
                                            [MWKSavedPageEntry new], url)]];
  [removedTitles minusSet:historyTitles];
  [self.dataStore removeArticlesWithURLsFromCache:[removedTitles allObjects]];
}

- (void)removeEntryWithListIndex:(NSURL *)url {
  if ([url.wmf_title length] == 0) {
    return;
  }
  [[NSNotificationCenter defaultCenter]
      postNotificationName:MWKSavedPageListDidUnsaveNotification
                    object:self
                  userInfo:@{MWKURLKey : url}];
  MWKSavedPageEntry *entry = [self entryForListIndex:url];
  if (entry) {
    [self cleanupRemovedEntries:@[ entry ]];
  }
  [super removeEntryWithListIndex:url];
}

- (void)removeAllEntries {
  [self.entries
      enumerateObjectsUsingBlock:^(MWKSavedPageEntry *_Nonnull obj,
                                   NSUInteger idx, BOOL *_Nonnull stop) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:MWKSavedPageListDidUnsaveNotification
                          object:self
                        userInfo:@{MWKURLKey : obj.url}];
      }];
  [self cleanupRemovedEntries:self.entries];
  [super removeAllEntries];
}

#pragma mark - Save

- (void)performSaveWithCompletion:(dispatch_block_t)completion
                            error:(WMFErrorHandler)errorHandler {
  NSError *error;
  if ([self.dataStore saveSavedPageList:self error:&error]) {
    if (completion) {
      completion();
    }
  } else {
    if (errorHandler) {
      errorHandler(error);
    }
  }
}

#pragma mark - Schema Migration

+ (NSArray<NSDictionary *> *)savedEntryDataFromExportedData:
    (NSDictionary *)savedPageListData {
  NSNumber *schemaVersionValue =
      savedPageListData[MWKSavedPageExportedSchemaVersionKey];
  MWKSavedPageListSchemaVersion schemaVersion =
      MWKSavedPageListSchemaVersionUnknown;
  if (schemaVersionValue) {
    schemaVersion = schemaVersionValue.unsignedIntegerValue;
  }
  switch (schemaVersion) {
  case MWKSavedPageListSchemaVersionCurrent:
    return savedPageListData[MWKSavedPageExportedEntriesKey];
  case MWKSavedPageListSchemaVersionUnknown:
    return [MWKSavedPageList
        savedEntryDataFromListWithUnknownSchema:savedPageListData];
  }
}

+ (NSArray<NSDictionary *> *)savedEntryDataFromListWithUnknownSchema:
    (NSDictionary *)data {
  return [data[MWKSavedPageExportedEntriesKey] wmf_reverseArray];
}

#pragma mark - Export

- (NSArray<NSDictionary *> *)exportedEntries {
  return [self.entries bk_map:^NSDictionary *(MWKSavedPageEntry *entry) {
    return [entry dataExport];
  }];
}

- (NSDictionary *)dataExport {
  return @{
    MWKSavedPageExportedSchemaVersionKey :
        @(MWKSavedPageListSchemaVersionCurrent),
    MWKSavedPageExportedEntriesKey : [self exportedEntries]
  };
}

@end
