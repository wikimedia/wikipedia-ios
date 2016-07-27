
#import "WMFHistoryTableViewController.h"
#import "PiwikTracker+WMFExtensions.h"
#import "NSUserActivity+WMFExtensions.h"

#import "NSString+WMFExtras.h"

#import "WMFRecentPagesDataSource.h"
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"

#import "MWKArticle.h"
#import "MWKSavedPageEntry.h"

#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"

@implementation WMFHistoryTableViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = MWLocalizedString(@"history-title", nil);
}

- (MWKHistoryList*)historyList {
    return self.dataStore.userDataStore.historyList;
}

- (MWKSavedPageList*)savedPageList {
    return self.dataStore.userDataStore.savedPageList;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];

    self.tableView.estimatedRowHeight = [WMFArticleListTableViewCell estimatedRowHeight];

    WMFRecentPagesDataSource* ds = [[WMFRecentPagesDataSource alloc] initWithRecentPagesList:[self historyList]];

    ds.cellClass = [WMFArticleListTableViewCell class];

    @weakify(self);
    ds.cellConfigureBlock = ^(WMFArticleListTableViewCell* cell,
                              MWKHistoryEntry* entry,
                              UITableView* tableView,
                              NSIndexPath* indexPath) {
        @strongify(self);
        MWKArticle* article = [[self dataStore] articleWithURL:entry.url];
        cell.titleText       = article.url.wmf_title;
        cell.descriptionText = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
        [cell setImage:[article bestThumbnailImage]];
    };

    self.dataSource = ds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PiwikTracker wmf_configuredInstance] wmf_logView:self];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_recentViewActivity]];
}

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNoHistory;
}

- (NSString*)analyticsContext {
    return @"Recent";
}

- (NSString*)analyticsName {
    return [self analyticsContext];
}

- (BOOL)showsDeleteAllButton {
    return YES;
}

- (NSString*)deleteButtonText {
    return MWLocalizedString(@"history-clear-all", nil);
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
