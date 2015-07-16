
#import "MediaWikiKit.h"

@interface MWKSavedPageList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

@end

@implementation MWKSavedPageList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSArray* entries = [[dataStore savedPageListData] bk_map:^id (id obj) {
        return [[MWKSavedPageEntry alloc] initWithDict:obj];
    }];

    self = [super initWithEntries:entries];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - Entry Access

- (MWKSavedPageEntry*)entryAtIndex:(NSUInteger)index {
    return [super entryAtIndex:index];
}

- (MWKSavedPageEntry*)entryForTitle:(MWKTitle*)title {
    return [super entryForListIndex:title];
}

- (BOOL)isSaved:(MWKTitle*)title {
    return [self containsEntryForListIndex:title];
}

- (NSUInteger)indexForEntry:(MWKHistoryEntry*)entry {
    return [super indexForEntry:entry];
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
    if ([self containsEntryForListIndex:entry.title]) {
        return;
    }
    [super addEntry:entry];
}

- (void)updateEntryWithTitle:(MWKTitle*)title update:(BOOL (^)(MWKSavedPageEntry*))update {
    [self updateEntryWithListIndex:title update:update];
}

- (void)removeSavedPageWithTitle:(MWKTitle*)title {
    if (title == nil) {
        return;
    }
    [self removeEntryWithListIndex:title];
}

- (void)removeAllSavedPages {
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

#pragma mark - Export

- (NSArray*)dataExport {
    return [self.entries bk_map:^id (MWKSavedPageEntry* obj) {
        return [obj dataExport];
    }];
}

@end
