
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
        [self sortEntries];
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

- (void)sortEntries {
    [self sortEntriesWithDescriptors:[[self class] sortDescriptors]];
}

- (MWKHistoryEntry*)addPageToHistoryWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    NSParameterAssert(title);
    if (title == nil) {
        return nil;
    }

    MWKHistoryEntry* entry = [self entryForTitle:title];
    if (!entry) {
        MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:title discoveryMethod:discoveryMethod];
        entry.date = [NSDate date];
    }
    entry.discoveryMethod = discoveryMethod;
    [self addEntry:entry];
    return entry;
}

- (void)addEntry:(MWKHistoryEntry*)entry {
    if ([entry.title.text length] == 0) {
        return;
    }
    if ([self containsEntryForListIndex:entry.title]) {
        [self updateEntryWithListIndex:entry.title update:^BOOL (MWKHistoryEntry* __nullable oldEntry) {
            oldEntry.discoveryMethod = entry.discoveryMethod == MWKHistoryDiscoveryMethodUnknown ?
                                       oldEntry.discoveryMethod : entry.discoveryMethod;
            if (oldEntry == entry && oldEntry.date == entry.date) {
                // adding the same entry is equivalent to updating it's timestamp
                oldEntry.date = [NSDate date];
            } else {
                // adding a manually-created entry updates the new one with its date
                oldEntry.date = entry.date;
            }
            return YES;
        }];
    } else {
        [super addEntry:entry];
    }
    [self sortEntries];
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

- (void)removeEntryWithListIndex:(id)listIndex {
    if ([[listIndex text] length] == 0) {
        return;
    }
    [super removeEntryWithListIndex:listIndex];
}

- (void)removeEntriesFromHistory:(NSArray*)historyEntries {
    if ([historyEntries count] == 0) {
        return;
    }
    [historyEntries enumerateObjectsUsingBlock:^(MWKHistoryEntry* entry, NSUInteger idx, BOOL* stop) {
        [self removeEntryWithListIndex:entry.title];
    }];
}

- (void)removeEntry:(id<MWKListObject>)entry {
    [super removeEntry:entry];
    [self sortEntries];
}

- (void)removeAllEntries {
    [super removeAllEntries];
    [self sortEntries];
}

+ (NSArray<NSSortDescriptor*>*)sortDescriptors {
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
