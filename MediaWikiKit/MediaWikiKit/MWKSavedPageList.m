
#import "MediaWikiKit.h"

@interface MWKSavedPageList ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

@end

@implementation MWKSavedPageList

#pragma mark - Setup

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSArray* entries = [[dataStore savedPageListData] bk_map:^id (id obj) {
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

#pragma mark - Entry Access

- (MWKSavedPageEntry*)mostRecentEntry {
    return [self.entries lastObject];
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
    MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithTitle:title];
    [self addEntry:entry];
}

- (void)addEntry:(MWKSavedPageEntry*)entry {
    if ([self isSaved:entry.title]) {
        return;
    }
    [super addEntry:entry];
}

- (void)insertEntry:(MWKSavedPageEntry*)entry atIndex:(NSUInteger)index {
    if ([self isSaved:entry.title]) {
        return;
    }
    [super insertEntry:entry atIndex:index];
}

- (void)removeEntryWithListIndex:(id)listIndex {
    if ([[listIndex text] length] == 0) {
        return;
    }
    [super removeEntryWithListIndex:listIndex];
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
