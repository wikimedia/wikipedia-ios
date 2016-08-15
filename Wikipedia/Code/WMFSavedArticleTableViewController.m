#import "WMFSavedArticleTableViewController.h"
#import "PiwikTracker+WMFExtensions.h"
#import "NSString+WMFExtras.h"
#import "NSUserActivity+WMFExtensions.h"

#import "WMFSavedPagesDataSource.h"
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"

#import "MWKArticle.h"
#import "MWKSavedPageEntry.h"

#import "WMFSaveButtonController.h"

#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"

@implementation WMFSavedArticleTableViewController

- (void)awakeFromNib {
  [super awakeFromNib];
  self.title = MWLocalizedString(@"saved-title", nil);
}

- (MWKSavedPageList *)savedPageList {
  return self.dataStore.userDataStore.savedPageList;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];

  self.tableView.estimatedRowHeight = [WMFArticleListTableViewCell estimatedRowHeight];

  WMFSavedPagesDataSource *ds = [[WMFSavedPagesDataSource alloc] initWithSavedPagesList:[self savedPageList]];

  ds.cellClass = [WMFArticleListTableViewCell class];

  @weakify(self);
  ds.cellConfigureBlock = ^(WMFArticleListTableViewCell *cell,
                            MWKSavedPageEntry *entry,
                            UITableView *tableView,
                            NSIndexPath *indexPath) {
    @strongify(self);
    MWKArticle *article = [[self dataStore] articleWithURL:entry.url];
    cell.titleText = article.url.wmf_title;
    cell.descriptionText = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImage:[article bestThumbnailImage]];
  };

  self.dataSource = ds;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [[PiwikTracker wmf_configuredInstance] wmf_logView:self];
  [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_savedPagesViewActivity]];
}

- (WMFEmptyViewType)emptyViewType {
  return WMFEmptyViewTypeNoSavedPages;
}

- (NSString *)analyticsContext {
  return @"Saved";
}

- (NSString *)analyticsName {
  return [self analyticsContext];
}

- (BOOL)showsDeleteAllButton {
  return YES;
}

- (NSString *)deleteButtonText {
  return MWLocalizedString(@"saved-clear-all", nil);
}

- (NSString *)deleteAllConfirmationText {
  return MWLocalizedString(@"saved-pages-clear-confirmation-heading", nil);
}

- (NSString *)deleteText {
  return MWLocalizedString(@"saved-pages-clear-delete-all", nil);
}

- (NSString *)deleteCancelText {
  return MWLocalizedString(@"saved-pages-clear-cancel", nil);
}

@end
