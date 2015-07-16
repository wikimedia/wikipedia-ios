

#import "MWKRecentSearchList.h"
#import "MediaWikiKit.h"

@interface MWKRecentSearchList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

@end

@implementation MWKRecentSearchList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSArray* entries = [[dataStore savedPageListData] bk_map:^id (id obj) {
        return [[MWKRecentSearchEntry alloc] initWithDict:obj];
    }];

    self = [super initWithEntries:entries];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - Data Update

- (void)addEntry:(MWKRecentSearchEntry*)entry {
    if (entry.searchTerm == nil) {
        return;
    }
    [self removeEntryWithListIndex:entry.searchTerm];
    [self insertEntry:entry atIndex:0];
}

#pragma mark - Entry Access

- (MWKRecentSearchEntry*)entryAtIndex:(NSUInteger)index {
    return [super entryAtIndex:index];
}

#pragma mark - Save

- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler {
    NSError* error;
    if ([self.dataStore saveRecentSearchList:self error:&error]) {
        if (completion) {
            completion();
        }
    } else {
        if (errorHandler) {
            errorHandler(error);
        }
    }
}

- (NSArray*)dataExport {
    return [self.entries bk_map:^id (MWKRecentSearchEntry* obj) {
        return [obj dataExport];
    }];
}

@end
