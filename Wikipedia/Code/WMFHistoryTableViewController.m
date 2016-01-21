
#import "WMFHistoryTableViewController.h"

#import "NSString+WMFExtras.h"

#import "WMFRecentPagesDataSource.h"
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"

#import "MWKArticle.h"
#import "MWKTitle.h"
#import "MWKSavedPageEntry.h"

#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"

@implementation WMFHistoryTableViewController

- (MWKHistoryList*)historyList {
    return self.dataStore.userDataStore.historyList;
}

- (MWKSavedPageList*)savedPageList {
    return self.dataStore.userDataStore.savedPageList;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = MWLocalizedString(@"history-title", nil);

    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];

    WMFRecentPagesDataSource* ds = [[WMFRecentPagesDataSource alloc] initWithRecentPagesList:[self historyList]];

    ds.cellClass = [WMFArticleListTableViewCell class];

    @weakify(self);
    ds.cellConfigureBlock = ^(WMFArticleListTableViewCell* cell,
                              MWKHistoryEntry* entry,
                              UITableView* tableView,
                              NSIndexPath* indexPath) {
        @strongify(self);
        MWKArticle* article = [[self dataStore] articleWithTitle:entry.title];
        cell.titleText       = article.title.text;
        cell.descriptionText = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
        [cell setImage:[article bestThumbnailImage]];
    };

    self.dataSource = ds;
}

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNoHistory;
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodUnknown;
}

- (NSString*)analyticsName {
    return @"Recent";
}

- (BOOL)showsDeleteAllButton {
    return YES;
}

- (NSString*)deleteAllConfirmationText {
    return MWLocalizedString(@"history-clear-confirmation-heading", nil);
}

- (NSString*)deleteText {
    return MWLocalizedString(@"history-clear-delete-all", nil);
}

- (NSString*)deleteCancelText {
    return MWLocalizedString(@"history-clear-cancel", nil);
}

@end
