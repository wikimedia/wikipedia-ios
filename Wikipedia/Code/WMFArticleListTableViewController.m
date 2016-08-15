#import "WMFArticleListTableViewController.h"

#import "MWKDataStore.h"
#import "MWKArticle.h"

#import <SSDataSources/SSDataSources.h>

#import "UIView+WMFDefaultNib.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "UIViewController+WMFEmptyView.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "UITableView+WMFLockedUpdates.h"

#import "UIViewController+WMFArticlePresentation.h"
#import "UIViewController+WMFSearch.h"

#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Wikipedia-Swift.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "PiwikTracker+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleListTableViewController () <
    UIViewControllerPreviewingDelegate>

@property(nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@end

@implementation WMFArticleListTableViewController

#pragma mark - Tear Down

- (void)dealloc {
  [self unobserveArticleUpdates];
  // NOTE(bgerstle): must check if dataSource was set to prevent creation of
  // KVOControllerNonRetaining during dealloc
  // happens during tests, creating KVOControllerNonRetaining during dealloc
  // attempts to create weak ref, causing crash
  if (self.dataSource) {
    [self.KVOControllerNonRetaining
        unobserve:self.dataSource
          keyPath:WMF_SAFE_KEYPATH(self.dataSource, urls)];
  }
}

#pragma mark - Accessors

- (void)setDataSource:
    (SSBaseDataSource<WMFTitleListDataSource> *__nullable)dataSource {
  if (_dataSource == dataSource) {
    return;
  }

  _dataSource.tableView = nil;
  self.tableView.dataSource = nil;

  [self.KVOControllerNonRetaining
      unobserve:self.dataSource
        keyPath:WMF_SAFE_KEYPATH(self.dataSource, urls)];

  _dataSource = dataSource;

  // HACK: Need to check the window to see if we are on screen.
  // http://stackoverflow.com/a/2777460/48311
  // isViewLoaded is not enough.
  if ([self isViewLoaded] && self.view.window) {
    if (_dataSource) {
      _dataSource.tableView = self.tableView;
    }
    [self.tableView wmf_scrollToTop:NO];
    [self.tableView reloadData];
  }

  [self updateDeleteButton];
  [self.KVOControllerNonRetaining
      observe:self.dataSource
      keyPath:WMF_SAFE_KEYPATH(self.dataSource, urls)
      options:NSKeyValueObservingOptionInitial
        block:^(WMFArticleListTableViewController *observer,
                SSBaseDataSource<WMFTitleListDataSource> *object,
                NSDictionary *change) {
          [observer updateDeleteButtonEnabledState];
          [observer updateEmptyState];
        }];
}

- (NSString *)debugDescription {
  return [NSString stringWithFormat:@"%@ dataSourceClass: %@", self,
                                    [self.dataSource class]];
}

#pragma mark - Delete Button

- (void)updateDeleteButton {
  if ([self showsDeleteAllButton] &&
      [self.dataSource respondsToSelector:@selector(deleteAll)]) {
    @weakify(self);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        bk_initWithTitle:[self deleteButtonText]
                   style:UIBarButtonItemStylePlain
                 handler:^(id sender) {
                   @strongify(self);
                   UIAlertController *sheet = [UIAlertController
                       alertControllerWithTitle:[self deleteAllConfirmationText]
                                        message:nil
                                 preferredStyle:
                                     UIAlertControllerStyleActionSheet];
                   [sheet addAction:
                              [UIAlertAction
                                  actionWithTitle:[self deleteText]
                                            style:UIAlertActionStyleDestructive
                                          handler:^(
                                              UIAlertAction *_Nonnull action) {
                                            [self.dataSource deleteAll];
                                            [self.tableView reloadData];
                                          }]];
                   [sheet addAction:[UIAlertAction
                                        actionWithTitle:[self deleteCancelText]
                                                  style:UIAlertActionStyleCancel
                                                handler:NULL]];
                   sheet.popoverPresentationController.barButtonItem = sender;
                   sheet.popoverPresentationController
                       .permittedArrowDirections = UIPopoverArrowDirectionAny;
                   [self presentViewController:sheet
                                      animated:YES
                                    completion:NULL];
                 }];
  } else {
    self.navigationItem.leftBarButtonItem = nil;
  }
}

- (void)updateDeleteButtonEnabledState {
  if ([self.dataSource titleCount] > 0) {
    self.navigationItem.leftBarButtonItem.enabled = YES;
  } else {
    self.navigationItem.leftBarButtonItem.enabled = NO;
  }
}

#pragma mark - Empty State

- (void)updateEmptyState {
  if (self.view.superview == nil) {
    return;
  }

  if ([self.dataSource titleCount] > 0) {
    [self wmf_hideEmptyView];
  } else {
    [self wmf_showEmptyViewOfType:[self emptyViewType]];
  }
}

#pragma mark - Stay Fresh... yo

- (void)observeArticleUpdates {
  [self unobserveArticleUpdates];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(articleUpdatedWithNotification:)
             name:MWKArticleSavedNotification
           object:nil];
}

- (void)unobserveArticleUpdates {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)articleUpdatedWithNotification:(NSNotification *)note {
  MWKArticle *article = note.userInfo[MWKArticleKey];
  [self updateDeleteButtonEnabledState];
  [self refreshAnyVisibleCellsWhichAreShowingArticleURL:article.url];
}

- (void)refreshAnyVisibleCellsWhichAreShowingArticleURL:(NSURL *)url {
  NSArray *indexPathsToRefresh = [[self.tableView indexPathsForVisibleRows]
      bk_select:^BOOL(NSIndexPath *indexPath) {
        NSURL *otherURL = [self.dataSource urlForIndexPath:indexPath];
        return [url isEqual:otherURL];
      }];

  [self.dataSource reloadCellsAtIndexPaths:indexPathsToRefresh];
}

#pragma mark - Previewing

- (void)registerForPreviewingIfAvailable {
  [self wmf_ifForceTouchAvailable:^{
    [self unregisterPreviewing];
    self.previewingContext =
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
  }
      unavailable:^{
        [self unregisterPreviewing];
      }];
}

- (void)unregisterPreviewing {
  if (self.previewingContext) {
    [self unregisterForPreviewingWithContext:self.previewingContext];
    self.previewingContext = nil;
  }
}

#pragma mark - UIViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return [self wmf_orientationMaskPortraitiPhoneAnyiPad];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.extendedLayoutIncludesOpaqueBars = YES;
  self.automaticallyAdjustsScrollViewInsets = YES;

  self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItem];

  self.tableView.backgroundColor = [UIColor wmf_articleListBackgroundColor];
  self.tableView.separatorColor = [UIColor wmf_lightGrayColor];
  self.tableView.estimatedRowHeight = 64.0;
  self.tableView.rowHeight = UITableViewAutomaticDimension;

  // HACK: this is the only way to force the table view to hide separators when
  // the table view is empty.
  // See: http://stackoverflow.com/a/5377805/48311
  self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

  _dataSource.tableView = self.tableView;

  [self observeArticleUpdates];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSParameterAssert(self.dataStore);
  self.dataSource.tableView = self.tableView;
  [self updateDeleteButtonEnabledState];
  [self updateEmptyState];
  [self registerForPreviewingIfAvailable];
}

- (void)traitCollectionDidChange:
    (nullable UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  [self registerForPreviewingIfAvailable];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
           (id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

  [coordinator animateAlongsideTransition:^(
                   id<UIViewControllerTransitionCoordinatorContext> context) {
    [self.tableView
        reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows
              withRowAnimation:UITableViewRowAnimationAutomatic];
  }
                               completion:NULL];
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self.dataSource canDeleteItemAtIndexpath:indexPath]) {
    return UITableViewCellEditingStyleDelete;
  } else {
    return UITableViewCellEditingStyleNone;
  }
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self
                                                              contentType:nil];
  [self wmf_hideKeyboard];
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  NSURL *url = [self.dataSource urlForIndexPath:indexPath];
  if (self.delegate) {
    [self.delegate listViewController:self didSelectArticleURL:url];
    return;
  }
  [self wmf_pushArticleWithURL:url dataStore:self.dataStore animated:YES];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (nullable UIViewController *)
        previewingContext:(id<UIViewControllerPreviewing>)previewingContext
viewControllerForLocation:(CGPoint)location {
  NSIndexPath *previewIndexPath =
      [self.tableView indexPathForRowAtPoint:location];
  if (!previewIndexPath) {
    return nil;
  }

  previewingContext.sourceRect =
      [self.tableView cellForRowAtIndexPath:previewIndexPath].frame;

  NSURL *url = [self.dataSource urlForIndexPath:previewIndexPath];
  id<WMFAnalyticsContentTypeProviding> contentType = nil;
  if ([self conformsToProtocol:@protocol(WMFAnalyticsContentTypeProviding)]) {
    contentType = (id<WMFAnalyticsContentTypeProviding>)self;
  }
  [[PiwikTracker wmf_configuredInstance]
      wmf_logActionPreviewInContext:self
                        contentType:contentType];

  if (self.delegate) {
    return [self.delegate listViewController:self
        viewControllerForPreviewingArticleURL:url];
  } else {
    return [[WMFArticleViewController alloc] initWithArticleURL:url
                                                      dataStore:self.dataStore];
  }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UINavigationController *)viewControllerToCommit {
  [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self
                                                              contentType:nil];
  if (self.delegate) {
    [self.delegate listViewController:self
        didCommitToPreviewedViewController:viewControllerToCommit];
  } else {
    [self wmf_pushArticleViewController:(WMFArticleViewController *)
                                            viewControllerToCommit
                               animated:YES];
  }
}

- (NSString *)analyticsContext {
  return @"Generic Article List";
}

- (WMFEmptyViewType)emptyViewType {
  return WMFEmptyViewTypeNone;
}

- (BOOL)showsDeleteAllButton {
  return NO;
}

- (NSString *)deleteButtonText {
  return nil;
}

- (NSString *)deleteAllConfirmationText {
  return nil;
}

- (NSString *)deleteText {
  return nil;
}

- (NSString *)deleteCancelText {
  return nil;
}

@end

NS_ASSUME_NONNULL_END