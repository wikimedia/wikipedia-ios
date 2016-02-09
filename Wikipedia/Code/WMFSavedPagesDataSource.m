
#import "WMFSavedPagesDataSource.h"
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSavedPagesDataSource ()

@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;

@end

@implementation WMFSavedPagesDataSource

- (nonnull instancetype)initWithSavedPagesList:(MWKSavedPageList*)savedPages {
    NSParameterAssert(savedPages);
    self = [super initWithTarget:savedPages keyPath:WMF_SAFE_KEYPATH(savedPages, entries)];
    if (self) {
        self.savedPageList = savedPages;

        self.tableDeletionBlock = ^(WMFSavedPagesDataSource* dataSource,
                                    UITableView* parentView,
                                    NSIndexPath* indexPath){
            [dataSource deleteArticleAtIndexPath:indexPath];
        };

        [self.KVOController observe:self.savedPageList keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionPrior block:^(WMFSavedPagesDataSource* observer, MWKSavedPageList* object, NSDictionary* change) {
            BOOL isPrior = [change[NSKeyValueChangeNotificationIsPriorKey] boolValue];
            NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
            NSIndexSet* indexes = change[NSKeyValueChangeIndexesKey];

            if (isPrior) {
                if (changeKind == NSKeyValueChangeSetting) {
                    [observer willChangeValueForKey:WMF_SAFE_KEYPATH(observer, titles)];
                } else {
                    [observer willChange:changeKind valuesAtIndexes:indexes forKey:WMF_SAFE_KEYPATH(observer, titles)];
                }
            } else {
                if (changeKind == NSKeyValueChangeSetting) {
                    [observer didChangeValueForKey:WMF_SAFE_KEYPATH(observer, titles)];
                } else {
                    [observer didChange:changeKind valuesAtIndexes:indexes forKey:WMF_SAFE_KEYPATH(observer, titles)];
                }
            }
        }];
    }
    return self;
}

- (NSArray*)titles {
    return [[self.savedPageList entries] bk_map:^id (MWKSavedPageEntry* obj) {
        return obj.title;
    }];
}

- (NSUInteger)titleCount {
    return [[self savedPageList] countOfEntries];
}

- (MWKSavedPageEntry*)savedPageForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPageList entryAtIndex:indexPath.row];
    return savedEntry;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    return savedEntry.title;
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    if (savedEntry) {
        [self.savedPageList removeEntryWithListIndex:savedEntry.title];
        [self.savedPageList save];
    }
}

- (void)deleteAll {
    [self.savedPageList removeAllEntries];
    [self.savedPageList save];
}

@end

NS_ASSUME_NONNULL_END