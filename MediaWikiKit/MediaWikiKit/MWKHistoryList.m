
#import "MediaWikiKit.h"

@interface MWKHistoryList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

@end

@implementation MWKHistoryList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSArray* entries = [[dataStore historyListData] bk_map:^id (id obj) {
        return [[MWKHistoryEntry alloc] initWithDict:obj];
    }];

    self = [super initWithEntries:entries];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - Entry Access

- (MWKHistoryEntry*)entryAtIndex:(NSUInteger)index {
    return [super entryAtIndex:index];
}

- (MWKHistoryEntry*)entryForTitle:(MWKTitle*)title {
    return [super entryForListIndex:title];
}

- (NSUInteger)indexForEntry:(MWKHistoryEntry*)entry {
    return [super indexForEntry:entry];
}

- (MWKHistoryEntry*)mostRecentEntry {
    return [self.entries lastObject];
}

#pragma mark - Update Methods

- (void)addPageToHistoryWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    if (title == nil) {
        return;
    }
    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:title discoveryMethod:discoveryMethod];
    entry.date = [NSDate date];

    [self addEntry:entry];
}

- (void)addEntry:(MWKHistoryEntry*)entry {
    if ([entry.title.text length] == 0) {
        return;
    }
    if ([self containsEntryForListIndex:entry.title]) {
        [self updateEntryWithListIndex:entry.title update:^BOOL (MWKHistoryEntry* __nullable oldEntry) {
            oldEntry.discoveryMethod = entry.discoveryMethod == MWKHistoryDiscoveryMethodUnknown ? oldEntry.discoveryMethod : entry.discoveryMethod;
            oldEntry.date = [NSDate date];
            return YES;
        }];
    } else {
        entry.date = [NSDate date];
        [super addEntry:entry];
    }
}

- (void)savePageScrollPosition:(CGFloat)scrollposition toPageInHistoryWithTitle:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return;
    }
    [self updateEntryWithListIndex:title update:^BOOL (MWKHistoryEntry* __nullable entry) {
        entry.scrollPosition = scrollposition;
        return YES;
    }];
}

- (void)removePageFromHistoryWithTitle:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return;
    }
    [self removeEntryWithListIndex:title];
}

- (void)removeEntriesFromHistory:(NSArray*)historyEntries {
    if ([historyEntries count] == 0) {
        return;
    }
    [historyEntries enumerateObjectsUsingBlock:^(MWKHistoryEntry* entry, NSUInteger idx, BOOL* stop) {
        [self removeEntryWithListIndex:entry.title];
    }];
}

- (void)removeAllEntriesFromHistory {
    [super removeAllEntries];
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
