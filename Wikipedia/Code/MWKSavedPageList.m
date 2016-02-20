#import "MWKSavedPageList.h"
#import "MWKDataStore.h"
#import "MWKSavedPageListDataExportConstants.h"
#import "MWKList+Subclass.h"
#import "Wikipedia-Swift.h"

NSString* const MWKSavedPageListDidSaveNotification   = @"MWKSavedPageListDidSaveNotification";
NSString* const MWKSavedPageListDidUnsaveNotification = @"MWKSavedPageListDidUnsaveNotification";

NSString* const MWKTitleKey = @"MWKTitleKey";

NSString* const MWKSavedPageExportedEntriesKey       = @"entries";
NSString* const MWKSavedPageExportedSchemaVersionKey = @"schemaVersion";

@interface MWKSavedPageList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

@end

@implementation MWKSavedPageList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSArray* entries =
        [[MWKSavedPageList savedEntryDataFromExportedData:[dataStore savedPageListData]] bk_map:^id (id obj) {
        @try {
            return [[MWKSavedPageEntry alloc] initWithDict:obj];
        } @catch (NSException* e) {
            NSLog(@"Encountered exception while reading entry %@: %@", e, obj);
            return nil;
        }
    }];

    entries = [entries bk_reject:^BOOL (id obj) {
        if ([obj isEqual:[NSNull null]]) {
            return YES;
        }
        return NO;
    }];

    self = [super initWithEntries:entries];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

- (void)importEntries:(NSArray*)entries {
    NSArray<MWKSavedPageEntry*>* validEntries = [entries bk_reject:^BOOL (MWKSavedPageEntry* entry) {
        return entry.title.text.length == 0;
    }];
    NSArray<MWKSavedPageEntry*>* uniqueValidEntries = [[NSOrderedSet orderedSetWithArray:validEntries] array];
    [super importEntries:uniqueValidEntries];
}

#pragma mark - Entry Access

- (MWKSavedPageEntry*)mostRecentEntry {
    return [self.entries firstObject];
}

- (MWKSavedPageEntry*)entryForListIndex:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return nil;
    }
    return [super entryForListIndex:title];
}

- (BOOL)isSaved:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return NO;
    }
    return [self containsEntryForListIndex:title];
}

#pragma mark - Update Methods

- (void)toggleSavedPageForTitle:(MWKTitle*)title {
    if ([self isSaved:title]) {
        [self removeEntryWithListIndex:title];
    } else {
        [self addSavedPageWithTitle:title];
    }
}

- (void)addSavedPageWithTitle:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return;
    }
    [self addEntry:[[MWKSavedPageEntry alloc] initWithTitle:title]];
}

- (void)addEntry:(MWKSavedPageEntry*)entry {
    if ([self isSaved:entry.title]) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKSavedPageListDidSaveNotification object:self userInfo:@{MWKTitleKey:entry.title}];
    [self insertEntry:entry atIndex:0];
}

- (void)removeEntryWithListIndex:(MWKTitle*)listIndex {
    if ([[listIndex text] length] == 0) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKSavedPageListDidUnsaveNotification object:self userInfo:@{MWKTitleKey:listIndex}];
    [super removeEntryWithListIndex:listIndex];
}

- (void)removeAllEntries{
    [self.entries enumerateObjectsUsingBlock:^(MWKSavedPageEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MWKSavedPageListDidUnsaveNotification object:self userInfo:@{MWKTitleKey:obj.title}];
    }];
    [super removeAllEntries];
}

#pragma mark - Save

- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler {
    NSError* error;
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

+ (NSArray<NSDictionary*>*)savedEntryDataFromExportedData:(NSDictionary*)savedPageListData {
    NSNumber* schemaVersionValue                = savedPageListData[MWKSavedPageExportedSchemaVersionKey];
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

+ (NSArray<NSDictionary*>*)savedEntryDataFromListWithUnknownSchema:(NSDictionary*)data {
    return [data[MWKSavedPageExportedEntriesKey] wmf_reverseArray];
}

#pragma mark - Export

- (NSArray<NSDictionary*>*)exportedEntries {
    return [self.entries bk_map:^NSDictionary*(MWKSavedPageEntry* entry) {
        return [entry dataExport];
    }];
}

- (NSDictionary*)dataExport {
    return @{
               MWKSavedPageExportedSchemaVersionKey: @(MWKSavedPageListSchemaVersionCurrent),
               MWKSavedPageExportedEntriesKey: [self exportedEntries]
    };
}

@end
