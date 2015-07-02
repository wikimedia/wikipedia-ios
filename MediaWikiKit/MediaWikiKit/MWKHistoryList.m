
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

@interface MWKHistoryList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;
@property (nonatomic, readwrite, assign) NSUInteger length;
@property (nonatomic, readwrite, strong) MWKHistoryEntry* mostRecentEntry;
@property (nonatomic, strong)  NSMutableArray* entries;
@property (nonatomic, strong) NSMutableDictionary* entriesByTitle;
@property (nonatomic, readwrite, assign) BOOL dirty;

@end

@implementation MWKHistoryList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.dataStore      = dataStore;
        self.entries        = [[NSMutableArray alloc] init];
        self.entriesByTitle = [[NSMutableDictionary alloc] init];
        NSDictionary* data = [self.dataStore historyListData];
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
            MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithDict:entryDict];
            [self.entries addObject:entry];
            self.entriesByTitle[entry.title] = entry;
        }
    }
    self.dirty = NO;
}

- (id)dataExport {
    NSMutableArray* array = [[NSMutableArray alloc] init];

    for (MWKHistoryEntry* entry in self.entries) {
        [array addObject:[entry dataExport]];
    }
    return @{@"entries": [NSArray arrayWithArray:array]};
}

#pragma mark - Entry Access

- (NSUInteger)length {
    return [self.entries count];
}

- (MWKHistoryEntry*)mostRecentEntry {
    return [self.entries firstObject];
}

- (MWKHistoryEntry*)entryAtIndex:(NSUInteger)index {
    return self.entries[index];
}

- (MWKHistoryEntry*)entryForTitle:(MWKTitle*)title {
    return self.entriesByTitle[title];
}

- (NSUInteger)indexForEntry:(MWKHistoryEntry*)entry {
    return [self.entries indexOfObject:entry];
}

- (MWKHistoryEntry*)entryAfterEntry:(MWKHistoryEntry*)entry {
    NSUInteger index = [self indexForEntry:entry];
    if (index == NSNotFound) {
        return nil;
    } else if (index > 0) {
        return [self entryAtIndex:index - 1];
    } else {
        return nil;
    }
}

- (MWKHistoryEntry*)entryBeforeEntry:(MWKHistoryEntry*)entry {
    NSUInteger index = [self indexForEntry:entry];
    if (index == NSNotFound) {
        return nil;
    } else if (index + 1 < self.length) {
        return [self entryAtIndex:index + 1];
    } else {
        return nil;
    }
}

#pragma mark - History Update

- (void)addPageToHistoryWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    if (title == nil) {
        return;
    }

    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:title discoveryMethod:discoveryMethod];
    entry.date = [NSDate date];

    [self addEntry:entry];
}

- (void)addEntry:(MWKHistoryEntry*)entry {
    if (entry.title == nil) {
        return;
    }

    MWKHistoryEntry* oldEntry = [self entryForTitle:entry.title];
    if (oldEntry) {
        entry.discoveryMethod = entry.discoveryMethod == MWKHistoryDiscoveryMethodUnknown ? oldEntry.discoveryMethod : entry.discoveryMethod;
        [self.entries removeObject:oldEntry];
    }
    entry.date = entry.date ? entry.date : [NSDate date];
    [self.entries insertObject:entry atIndex:0];
    self.entriesByTitle[entry.title] = entry;
    self.dirty                       = YES;
}

- (void)savePageScrollPosition:(CGFloat)scrollposition toPageInHistoryWithTitle:(MWKTitle*)title {
    if (title == nil) {
        return;
    }

    MWKHistoryEntry* entry = [self entryForTitle:title];

    if (entry) {
        entry.scrollPosition = scrollposition;
        self.dirty           = YES;
    }
}

- (void)removePageFromHistoryWithTitle:(MWKTitle*)title {
    if (title == nil) {
        return;
    }

    MWKHistoryEntry* entry = [self entryForTitle:title];
    if (entry) {
        [self.entries removeObject:entry];
        [self.entriesByTitle removeObjectForKey:entry.title];
        self.dirty = YES;
    }
}

- (void)removeEntriesFromHistory:(NSArray*)historyEntries {
    if ([historyEntries count] == 0) {
        return;
    }

    [historyEntries enumerateObjectsUsingBlock:^(MWKHistoryEntry* entry, NSUInteger idx, BOOL* stop) {
        [self.entries removeObject:entry];
        [self.entriesByTitle removeObjectForKey:entry.title];
    }];

    self.dirty = YES;
}

- (void)removeAllEntriesFromHistory {
    [self.entries removeAllObjects];
    [self.entriesByTitle removeAllObjects];
    self.dirty = YES;
}

#pragma mark - Save

- (AnyPromise*)save {
    return dispatch_promise_on(dispatch_get_main_queue(), ^{
        NSError* error;
        if (self.dirty && ![self.dataStore saveHistoryList:self error:&error]) {
            NSAssert(NO, @"Error saving history: %@", [error localizedDescription]);
            return [AnyPromise promiseWithValue:error];
        } else {
            self.dirty = NO;
        }

        return [AnyPromise promiseWithValue:nil];
    });
}

@end
