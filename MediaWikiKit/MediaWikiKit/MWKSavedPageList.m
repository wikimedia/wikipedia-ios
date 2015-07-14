
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

@interface MWKSavedPageList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;
@property (nonatomic, strong) NSMutableArray* mutableEntries;
@property (nonatomic, strong) NSMutableDictionary* entriesByTitle;
@property (readwrite, nonatomic, assign) BOOL dirty;

@end

@implementation MWKSavedPageList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.dataStore      = dataStore;
        self.mutableEntries = [NSMutableArray array];
        self.entriesByTitle = [NSMutableDictionary dictionary];
        NSDictionary* data = [self.dataStore savedPageListData];

        [self importData:data];
    }
    return self;
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state
                                  objects:(__unsafe_unretained id [])stackbuf
                                    count:(NSUInteger)len {
    return [self.entries countByEnumeratingWithState:state objects:stackbuf count:len];
}

#pragma mark - Data methods

- (void)importData:(NSDictionary*)data {
    NSArray* arr = data[@"entries"];
    if (arr) {
        for (NSDictionary* entryDict in arr) {
            MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithDict:entryDict];
            [self.mutableEntries addObject:entry];
            self.entriesByTitle[entry.title] = entry;
        }
    }
    self.dirty = NO;
}

- (id)dataExport {
    NSMutableArray* array = [[NSMutableArray alloc] init];

    for (MWKSavedPageEntry* entry in self.entries) {
        [array addObject:[entry dataExport]];
    }

    return @{@"entries": [NSArray arrayWithArray:array]};
}

#pragma mark - Entry Access

- (NSArray*)entries {
    return _mutableEntries;
}

- (NSMutableArray*)mutableEntries {
    return [self mutableArrayValueForKey:@"entries"];
}

- (NSUInteger)length {
    return [self countOfEntries];
}

- (MWKSavedPageEntry*)entryAtIndex:(NSUInteger)index {
    return [self objectInEntriesAtIndex:index];
}

- (MWKSavedPageEntry*)entryForTitle:(MWKTitle*)title {
    return self.entriesByTitle[title];
}

- (BOOL)isSaved:(MWKTitle*)title {
    MWKSavedPageEntry* entry = [self entryForTitle:title];
    return (entry != nil);
}

- (NSUInteger)indexForEntry:(MWKHistoryEntry*)entry {
    return [self.mutableEntries indexOfObject:entry];
}

#pragma mark - Update Methods

- (void)toggleSavedPageForTitle:(MWKTitle*)title {
    if ([self isSaved:title]) {
        [self removeSavedPageWithTitle:title];
    } else {
        [self addSavedPageWithTitle:title];
    }
}

- (void)addSavedPageWithTitle:(MWKTitle*)title {
    if (title == nil) {
        return;
    }

    MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithTitle:title];
    [self addEntry:entry];
}

- (void)addEntry:(MWKSavedPageEntry*)entry {
    if (entry.title == nil) {
        return;
    }

    MWKSavedPageEntry* newEntry = entry;
    MWKSavedPageEntry* oldEntry = [self entryForTitle:entry.title];
    if (oldEntry) {
        [self.mutableEntries removeObject:oldEntry];
    }

    self.entriesByTitle[newEntry.title] = newEntry;
    [self.mutableEntries insertObject:newEntry atIndex:0];
    self.dirty = YES;
}

- (void)updateEntryWithTitle:(MWKTitle*)title update:(BOOL (^)(MWKSavedPageEntry*))update {
    MWKSavedPageEntry* entry = [self entryForTitle:title];
    if (entry) {
        // prevent reseting "dirty" if block returns NO and dirty was already YES
        self.dirty |= update(entry);
    }
}

- (void)removeSavedPageWithTitle:(MWKTitle*)title {
    if (title == nil) {
        return;
    }

    MWKSavedPageEntry* entry = [self entryForTitle:title];

    if (entry) {
        [self.mutableEntries removeObject:entry];
        [self.entriesByTitle removeObjectForKey:entry.title];
        self.dirty = YES;
    }
}

- (void)removeAllSavedPages {
    [self.mutableEntries removeAllObjects];
    [self.entriesByTitle removeAllObjects];
    self.dirty = YES;
}

#pragma mark - Save

- (AnyPromise*)save {
    return dispatch_promise_on(dispatch_get_main_queue(), ^{
        NSError* error;
        if (self.dirty && ![self.dataStore saveSavedPageList:self error:&error]) {
            NSAssert(NO, @"Error saving saved pages: %@", [error localizedDescription]);
            return [AnyPromise promiseWithValue:error];
        } else {
            self.dirty = NO;
        }

        return [AnyPromise promiseWithValue:nil];
    });
}

#pragma mark - KVO

- (NSUInteger)countOfEntries {
    return [_mutableEntries count];
}

- (id)objectInEntriesAtIndex:(NSUInteger)idx {
    return [_mutableEntries objectAtIndex:idx];
}

- (void)insertObject:(id)anObject inEntriesAtIndex:(NSUInteger)idx {
    [_mutableEntries insertObject:anObject atIndex:idx];
}

- (void)insertEntries:(NSArray*)entrieArray atIndexes:(NSIndexSet*)indexes {
    [_mutableEntries insertObjects:entrieArray atIndexes:indexes];
}

- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx {
    [_mutableEntries removeObjectAtIndex:idx];
}

- (void)removeEntriesAtIndexes:(NSIndexSet*)indexes {
    [_mutableEntries removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(id)anObject {
    [_mutableEntries replaceObjectAtIndex:idx withObject:anObject];
}

- (void)replaceEntriesAtIndexes:(NSIndexSet*)indexes withEntries:(NSArray*)entrieArray {
    [_mutableEntries replaceObjectsAtIndexes:indexes withObjects:entrieArray];
}

@end
