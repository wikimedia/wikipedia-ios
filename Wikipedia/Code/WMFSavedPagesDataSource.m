
#import "WMFSavedPagesDataSource.h"
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"
#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "NSString+Extras.h"
#import "UITableViewCell+WMFLayout.h"
#import "WMFSaveButtonController.h"


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

        self.cellClass = [WMFArticlePreviewTableViewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticlePreviewTableViewCell* cell,
                                    MWKSavedPageEntry* entry,
                                    UITableView* tableView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKArticle* article = [[self dataStore] articleWithTitle:entry.title];
            [cell setSaveableTitle:article.title savedPageList:self.savedPageList];
            cell.titleText       = article.title.text;
            cell.descriptionText = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
            cell.snippetText     = [article summary];
            [cell setImage:[article bestThumbnailImage]];
            [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
            cell.saveButtonController.analyticsSource = self;
        };

        self.tableDeletionBlock = ^(WMFSavedPagesDataSource* dataSource,
                                    UITableView* parentView,
                                    NSIndexPath* indexPath){
            [parentView beginUpdates];
            [dataSource deleteArticleAtIndexPath:indexPath];
            [parentView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [parentView endUpdates];
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

- (void)setTableView:(nullable UITableView*)tableView {
    [super setTableView:tableView];
    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
}

- (NSArray*)titles {
    return [[self.savedPageList entries] bk_map:^id (MWKSavedPageEntry* obj) {
        return obj.title;
    }];
}

- (NSUInteger)titleCount {
    return [[self savedPageList] countOfEntries];
}

- (MWKDataStore*)dataStore {
    return self.savedPageList.dataStore;
}

- (nullable NSString*)displayTitle {
    return MWLocalizedString(@"saved-pages-title", nil);
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

- (BOOL)showsDeleteAllButton {
    return YES;
}

- (NSString*)deleteAllConfirmationText {
    return MWLocalizedString(@"saved-pages-clear-confirmation-heading", nil);
}

- (NSString*)deleteText {
    return MWLocalizedString(@"saved-pages-clear-delete-all", nil);
}

- (NSString*)deleteCancelText {
    return MWLocalizedString(@"saved-pages-clear-cancel", nil);
}

- (void)deleteAll {
    [self.savedPageList removeAllEntries];
    [self.savedPageList save];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSaved;
}

- (NSString*)analyticsName {
    return @"Saved";
}

@end

NS_ASSUME_NONNULL_END