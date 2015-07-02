

#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

@interface MWKRecentSearchList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;
@property (readwrite, nonatomic, assign) NSUInteger length;
@property (readwrite, nonatomic, assign) BOOL dirty;
@property (nonatomic, strong) NSMutableArray* entries;

@end

@implementation MWKRecentSearchList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        self.entries   = [[NSMutableArray alloc] init];
        NSDictionary* data = [self.dataStore historyListData];
        [self importData:data];
    }
    return self;
}

#pragma mark - Data methods

- (void)importData:(NSDictionary*)data {
    for (NSDictionary* entryDict in data[@"entries"]) {
        MWKRecentSearchEntry* entry = [[MWKRecentSearchEntry alloc] initWithDict:entryDict];
        [self.entries addObject:entry];
    }
    self.dirty = NO;
}

- (id)dataExport {
    NSMutableArray* dicts = [[NSMutableArray alloc] init];
    for (MWKRecentSearchEntry* entry in self.entries) {
        [dicts addObject:[entry dataExport]];
    }
    return @{@"entries": dicts};
}

#pragma mark - Data Update

- (AnyPromise*)addEntry:(MWKRecentSearchEntry*)entry {
    if (entry.searchTerm == nil) {
        return [AnyPromise promiseWithValue:[NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]];
    }

    return dispatch_promise_on(dispatch_get_main_queue(), ^{
        NSUInteger oldIndex = [self.entries indexOfObject:entry];
        if (oldIndex != NSNotFound) {
            // Move to top!
            [self.entries removeObjectAtIndex:oldIndex];
        }
        [self.entries insertObject:entry atIndex:0];
        self.dirty = YES;
        // @todo trim to max?

        return [AnyPromise promiseWithValue:entry];
    });
}

#pragma mark - Entry Access

- (MWKRecentSearchEntry*)entryAtIndex:(NSUInteger)index {
    return self.entries[index];
}

#pragma mark - Save

- (AnyPromise*)save {
    return dispatch_promise_on(dispatch_get_main_queue(), ^{
        NSError* error;
        if (self.dirty && ![self.dataStore saveRecentSearchList:self error:&error]) {
            NSAssert(NO, @"Error saving saved pages: %@", [error localizedDescription]);
            return [AnyPromise promiseWithValue:error];
        } else {
            self.dirty = NO;
        }

        return [AnyPromise promiseWithValue:nil];
    });
}

@end
