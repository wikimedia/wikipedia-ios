
#import "WMFSavedPagesDataSource.h"
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"
#import "MWKArticle.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFSavedPagesDataSource ()

@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPages;

@end

@implementation WMFSavedPagesDataSource

- (nonnull instancetype)initWithSavedPagesList:(MWKSavedPageList*)savedPages {
    self = [super init];
    if (self) {
        self.savedPages = savedPages;
        [self.KVOController observe:savedPages keyPath:WMF_SAFE_KEYPATH(savedPages, entries) options:NSKeyValueObservingOptionPrior block:^(id observer, id object, NSDictionary* change) {
            NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];

            if ([change[NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
                [self willChange:changeKind valuesAtIndexes:change[NSKeyValueChangeIndexesKey] forKey:@"articles"];
            } else {
                [self didChange:changeKind valuesAtIndexes:change[NSKeyValueChangeIndexesKey] forKey:@"articles"];
            }
        }];
    }
    return self;
}

- (NSArray*)articles {
    return [[self.savedPages entries] bk_map:^id (id obj) {
        return [self articleForEntry:obj];
    }];
}

- (MWKArticle*)articleForEntry:(MWKSavedPageEntry*)entry {
    return [[self dataStore] articleWithTitle:entry.title];
}

- (MWKDataStore*)dataStore {
    return self.savedPages.dataStore;
}

- (nullable NSString*)displayTitle {
    return MWLocalizedString(@"saved-pages-title", nil);
}

- (NSUInteger)articleCount {
    return [[self savedPages] length];
}

- (MWKSavedPageEntry*)savedPageForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPages entryAtIndex:indexPath.row];
    return savedEntry;
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    return [self articleForEntry:savedEntry];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    if (savedEntry) {
        [self.savedPages removeSavedPageWithTitle:savedEntry.title];
        [self.savedPages save];
    }
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSaved;
}

@end

NS_ASSUME_NONNULL_END