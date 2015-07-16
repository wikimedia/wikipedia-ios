
#import "WMFRecentPagesDataSource.h"
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKArticle.h"
#import "MediaWikiKit.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFRecentPagesDataSource ()

@property (nonatomic, strong, readwrite) MWKHistoryList* recentPages;

@end

@implementation WMFRecentPagesDataSource

- (nonnull instancetype)initWithRecentPagesList:(MWKHistoryList*)recentPages {
    self = [super init];
    if (self) {
        self.recentPages = recentPages;
        [self.KVOController observe:recentPages keyPath:WMF_SAFE_KEYPATH(recentPages, entries) options:NSKeyValueObservingOptionPrior block:^(id observer, id object, NSDictionary* change) {
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
    return [[self.recentPages entries] bk_map:^id (id obj) {
        return [self articleForEntry:obj];
    }];
}

- (MWKArticle*)articleForEntry:(MWKHistoryEntry*)entry {
    return [[self dataStore] articleWithTitle:entry.title];
}

- (MWKDataStore*)dataStore {
    return self.recentPages.dataStore;
}

- (nullable NSString*)displayTitle {
    return MWLocalizedString(@"page-history-title", nil);
}

- (NSUInteger)articleCount {
    return [[self recentPages] countOfEntries];
}

- (MWKHistoryEntry*)recentPageForIndexPath:(NSIndexPath*)indexPath {
    MWKHistoryEntry* entry = [self.recentPages entryAtIndex:indexPath.row];
    return entry;
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    MWKHistoryEntry* entry = [self recentPageForIndexPath:indexPath];
    return [self articleForEntry:entry];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath {
    MWKHistoryEntry* entry = [self recentPageForIndexPath:indexPath];
    if (entry) {
        [self.recentPages removePageFromHistoryWithTitle:entry.title];
        [self.recentPages save];
    }
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodUnknown;
}

@end

NS_ASSUME_NONNULL_END

