
#import "MediaWikiKit.h"
#import "MWKList+Subclass.h"

#if DEBUG
#define MAX_HISTORY_ENTRIES 3
#else
#define MAX_HISTORY_ENTRIES 100
#endif


NS_ASSUME_NONNULL_BEGIN

NSString* const MWKHistoryListDidUpdateNotification = @"MWKHistoryListDidUpdateNotification";

@interface MWKHistoryList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

@end

@implementation MWKHistoryList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSArray* entries = [[[dataStore historyListData] bk_map:^id (id obj) {
        @try {
            return [[MWKHistoryEntry alloc] initWithDict:obj];
        } @catch (NSException* exception) {
            return nil;
        }
    }] bk_reject:^BOOL (id obj) {
        return [obj isEqual:[NSNull null]];
    }];

    self = [super initWithEntries:entries];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - Entry Access

- (nullable MWKHistoryEntry*)mostRecentEntry {
    return [self.entries firstObject];
}

- (nullable MWKHistoryEntry*)entryForTitle:(MWKTitle*)title {
    return [self entryForListIndex:title];
}

#pragma mark - Update Methods

- (MWKHistoryEntry*)addPageToHistoryWithTitle:(MWKTitle*)title {
    NSParameterAssert(title);
    if ([title isNonStandardTitle]) {
        return nil;
    }
    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:title];
    [self addEntry:entry];
    return entry;
}

- (void)addEntry:(MWKHistoryEntry*)entry {
    if ([entry.title.text length] == 0) {
        return;
    }
    MWKHistoryEntry* oldEntry = [self entryForListIndex:entry.title];
    if (oldEntry) {
        [super removeEntry:oldEntry];
    }
    [super addEntry:entry];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
}

- (void)setPageScrollPosition:(CGFloat)scrollposition onPageInHistoryWithTitle:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return;
    }
    [self updateEntryWithListIndex:title update:^BOOL (MWKHistoryEntry* __nullable entry) {
        entry.scrollPosition = scrollposition;
        return YES;
    }];
}

- (void)setSignificantlyViewedOnPageInHistoryWithTitle:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return;
    }
    [self updateEntryWithListIndex:title update:^BOOL (MWKHistoryEntry* __nullable entry) {
        if (entry.titleWasSignificantlyViewed) {
            return NO;
        }
        entry.titleWasSignificantlyViewed = YES;
        return YES;
    }];
}

- (void)cleanupRemovedEntries:(NSArray<MWKHistoryEntry*>*)entries {
    if (entries == nil || entries.count == 0) {
        return;
    }
    MWKSavedPageList* savedPageList = self.dataStore.userDataStore.savedPageList;
    NSSet* savedTitles              = [NSSet setWithArray:[savedPageList.entries valueForKey:@"title"]];
    NSMutableSet* removedTitles     = [NSMutableSet setWithArray:[entries valueForKey:@"title"]];
    [removedTitles minusSet:savedTitles];
    [self.dataStore removeTitlesFromCache:[removedTitles allObjects]];
}

- (void)removeEntry:(MWKListEntry)entry {
    [super removeEntry:entry];
    if (entry != nil) {
        [self cleanupRemovedEntries:@[entry]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
}

- (void)removeEntryWithListIndex:(id)listIndex {
    if ([[listIndex text] length] == 0) {
        return;
    }
    MWKHistoryEntry* entry = [self entryForListIndex:listIndex];
    if (entry != nil) {
        [self cleanupRemovedEntries:@[entry]];
    }
    [super removeEntryWithListIndex:listIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
}

- (void)removeEntriesFromHistory:(NSArray*)historyEntries {
    if ([historyEntries count] == 0) {
        return;
    }
    [self cleanupRemovedEntries:historyEntries];
    [historyEntries enumerateObjectsUsingBlock:^(MWKHistoryEntry* entry, NSUInteger idx, BOOL* stop) {
        [self removeEntryWithListIndex:entry.title];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
}

- (void)removeAllEntries {
    [self cleanupRemovedEntries:[self.entries copy]];
    [super removeAllEntries];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
}

- (void)prune {
    NSArray* removed = [super pruneToMaximumCount:MAX_HISTORY_ENTRIES];
    [self cleanupRemovedEntries:removed];
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
}

#pragma mark - Sort Descriptors

- (nullable NSArray<NSSortDescriptor*>*)sortDescriptors {
    static NSArray<NSSortDescriptor*>* sortDescriptors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH([MWKHistoryEntry new], date)
                                                          ascending:NO]];
    });
    return sortDescriptors;
}

#pragma mark - Save

- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler {
    NSError* error;
    if ([self.dataStore saveHistoryList:self error:&error]) {
        if (completion) {
            completion();
        }
    } else {
        if (errorHandler) {
            errorHandler(error);
        }
    }
}

#pragma mark - Export

- (NSArray*)dataExport {
    return [self.entries bk_map:^id (MWKHistoryEntry* obj) {
        return [obj dataExport];
    }];
}

@end

NS_ASSUME_NONNULL_END
