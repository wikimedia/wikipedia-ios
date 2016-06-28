
#import "MediaWikiKit.h"
#import "MWKList+Subclass.h"

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

- (nullable MWKHistoryEntry*)entryForURL:(NSURL*)url {
    return [self entryForListIndex:url];
}

#pragma mark - Update Methods

- (MWKHistoryEntry*)addPageToHistoryWithURL:(NSURL*)url {
    NSParameterAssert(url);
    if ([url wmf_isNonStandardURL]) {
        return nil;
    }
    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithURL:url];
    [self addEntry:entry];
    return entry;
}

- (void)addEntry:(MWKHistoryEntry*)entry {
    if ([entry.url.wmf_title length] == 0) {
        return;
    }
    MWKHistoryEntry* oldEntry = [self entryForListIndex:entry.url];
    if (oldEntry) {
        [super removeEntry:oldEntry];
    }
    [super addEntry:entry];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
}

- (void)setPageScrollPosition:(CGFloat)scrollposition onPageInHistoryWithURL:(NSURL*)url {
    if ([url.wmf_title length] == 0) {
        return;
    }
    [self updateEntryWithListIndex:url update:^BOOL (MWKHistoryEntry* __nullable entry) {
        entry.scrollPosition = scrollposition;
        return YES;
    }];
}

- (void)setSignificantlyViewedOnPageInHistoryWithURL:(NSURL*)url {
    if ([url.wmf_title length] == 0) {
        return;
    }
    [self updateEntryWithListIndex:url update:^BOOL (MWKHistoryEntry* __nullable entry) {
        if (entry.titleWasSignificantlyViewed) {
            return NO;
        }
        entry.titleWasSignificantlyViewed = YES;
        return YES;
    }];
}

- (void)removeEntry:(MWKListEntry)entry {
    [super removeEntry:entry];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
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
        [self removeEntryWithListIndex:entry.url];
    }];
}

- (void)removeAllEntries {
    [super removeAllEntries];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKHistoryListDidUpdateNotification object:self];
}

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
