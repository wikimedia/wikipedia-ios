
#import "WMFArticleListTableViewController.h"

#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "MWKTitle.h"

#import <SSDataSources/SSDataSources.h>

#import "UIView+WMFDefaultNib.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "UIScrollView+WMFContentOffsetUtils.h"

#import "WMFArticleContainerViewController.h"
#import "UIViewController+WMFSearchButton.h"
#import "UIViewController+WMFArticlePresentation.h"

#import "WMFIntrinsicSizeTableView.h"

#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Wikipedia-Swift.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "PiwikTracker+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleListTableViewController ()<WMFSearchPresentationDelegate, UIViewControllerPreviewingDelegate>

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;
@property (nonatomic, strong, null_resettable) MWKTitle* previewingTitle;

@end

@implementation WMFArticleListTableViewController

#pragma mark - Tear Down

- (void)dealloc {
    [self unobserveArticleUpdates];
}

#pragma mark - Accessors

- (id<WMFArticleListDynamicDataSource>)dynamicDataSource {
    if ([self.dataSource conformsToProtocol:@protocol(WMFArticleListDynamicDataSource)]) {
        return (id<WMFArticleListDynamicDataSource>)self.dataSource;
    }
    return nil;
}

- (void)setDataSource:(SSBaseDataSource<WMFTitleListDataSource>* __nullable)dataSource {
    if ([_dataSource isEqual:dataSource]) {
        return;
    }

    _dataSource.tableView     = nil;
    self.tableView.dataSource = nil;

    [self.KVOController unobserve:self.dataSource keyPath:WMF_SAFE_KEYPATH(self.dataSource, titles)];

    _dataSource = dataSource;

    //HACK: Need to check the window to see if we are on screen. http://stackoverflow.com/a/2777460/48311
    //isViewLoaded is not enough.
    if ([self isViewLoaded] && self.view.window) {
        if (_dataSource) {
            [self connectTableViewAndDataSource];
            [[self dynamicDataSource] startUpdating];
        }
        [self.tableView wmf_scrollToTop:NO];
        [self.tableView reloadData];
    }

    self.title = [_dataSource displayTitle];
    [self updateDeleteButton];
    [self.KVOController observe:self.dataSource keyPath:WMF_SAFE_KEYPATH(self.dataSource, titles) options:NSKeyValueObservingOptionInitial block:^(WMFArticleListTableViewController* observer, SSBaseDataSource < WMFTitleListDataSource > * object, NSDictionary* change) {
        [self updateDeleteButtonEnabledState];
    }];
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"%@ dataSourceClass: %@", self, [self.dataSource class]];
}

#pragma mark - DataSource and Collection View Wiring

- (void)connectTableViewAndDataSource {
    _dataSource.tableView = self.tableView;
    if ([_dataSource respondsToSelector:@selector(estimatedItemHeight)]) {
        self.tableView.estimatedRowHeight = _dataSource.estimatedItemHeight;
    }
}

#pragma mark - Delete Button

- (void)updateDeleteButton {
    //TODO: disabling until new designs are made
    return;
    if ([self.dataSource conformsToProtocol:@protocol(WMFArticleDeleteAllDataSource)]) {
        id<WMFArticleDeleteAllDataSource> deleteableDataSource = (id<WMFArticleDeleteAllDataSource>)self.dataSource;

        if ([deleteableDataSource showsDeleteAllButton] == YES) {
            @weakify(self);
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"trash"] style:UIBarButtonItemStylePlain handler:^(id sender) {
                @strongify(self);
                UIActionSheet* sheet = [UIActionSheet bk_actionSheetWithTitle:[deleteableDataSource deleteAllConfirmationText]];
                [sheet bk_setDestructiveButtonWithTitle:[deleteableDataSource deleteText] handler:^{
                    [deleteableDataSource deleteAll];
                    [self.tableView reloadData];
                }];
                [sheet bk_setCancelButtonWithTitle:[deleteableDataSource deleteCancelText] handler:NULL];
                [sheet showFromTabBar:self.navigationController.tabBarController.tabBar];
            }];
            return;
        }
    }
    self.navigationItem.leftBarButtonItem = nil;
}

- (void)updateDeleteButtonEnabledState {
    //TODO: disabling until new designs are made
    if ([self.dataSource titleCount] > 0) {
        self.navigationItem.leftBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.leftBarButtonItem.enabled = NO;
    }
}

#pragma mark - Stay Fresh... yo

- (void)observeArticleUpdates {
    [self unobserveArticleUpdates];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleUpdatedWithNotification:) name:MWKArticleSavedNotification object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKArticleSavedNotification object:nil];
}

- (void)articleUpdatedWithNotification:(NSNotification*)note {
    MWKArticle* article = note.userInfo[MWKArticleKey];
    [self updateDeleteButtonEnabledState];
    [self refreshAnyVisibleCellsWhichAreShowingTitle:article.title];
}

- (void)refreshAnyVisibleCellsWhichAreShowingTitle:(MWKTitle*)title {
    NSArray* indexPathsToRefresh = [[self.tableView indexPathsForVisibleRows] bk_select:^BOOL (NSIndexPath* indexPath) {
        MWKTitle* otherTitle = [self.dataSource titleForIndexPath:indexPath];
        return [title isEqualToTitle:otherTitle];
    }];
    [self.tableView reloadRowsAtIndexPaths:indexPathsToRefresh withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Previewing

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterPreviewing];
        self.previewingContext = [self registerForPreviewingWithDelegate:self
                                                              sourceView:self.tableView];
    } unavailable:^{
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

- (void)viewDidLoad {
    [super viewDidLoad];

    self.extendedLayoutIncludesOpaqueBars     = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;

    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItemWithDelegate:self];

    self.tableView.backgroundColor    = [UIColor wmf_articleListBackgroundColor];
    self.tableView.separatorColor     = [UIColor wmf_lightGrayColor];
    self.tableView.estimatedRowHeight = 64.0;
    self.tableView.rowHeight          = UITableViewAutomaticDimension;

    //HACK: this is the only way to force the table view to hide separators when the table view is empty.
    //See: http://stackoverflow.com/a/5377805/48311
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [self connectTableViewAndDataSource];
    [self observeArticleUpdates];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSParameterAssert(self.dataStore);
    [self connectTableViewAndDataSource];
    [self updateDeleteButtonEnabledState];
    [[self dynamicDataSource] startUpdating];
    [self registerForPreviewingIfAvailable];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.previewingTitle) {
        [[PiwikTracker sharedInstance] wmf_logActionPreviewDismissedForTitle:self.previewingTitle fromSource:self];
        self.previewingTitle = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[self dynamicDataSource] stopUpdating];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection*)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context) {
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:NULL];
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([self.dataSource canDeleteItemAtIndexpath:indexPath]) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self wmf_hideKeyboard];
    MWKTitle* title = [self.dataSource titleForIndexPath:indexPath];
    if (self.delegate) {
        [self.delegate didSelectTitle:title
                               sender:self
                      discoveryMethod:self.dataSource.discoveryMethod];
        return;
    }
    [self wmf_pushArticleViewControllerWithTitle:title
                                 discoveryMethod:[self.dataSource discoveryMethod]
                                       dataStore:self.dataStore];
}

#pragma mark - WMFSearchPresentationDelegate

- (MWKDataStore*)searchDataStore {
    return self.dataStore;
}

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:title
                                     discoveryMethod:discoveryMethod
                                           dataStore:self.dataStore];
    }];
}

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewController:articleViewController];
    }];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (nullable UIViewController*)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                      viewControllerForLocation:(CGPoint)location {
    NSIndexPath* previewIndexPath = [self.tableView indexPathForRowAtPoint:location];
    if (!previewIndexPath) {
        return nil;
    }

    previewingContext.sourceRect = [self.tableView cellForRowAtIndexPath:previewIndexPath].frame;

    MWKTitle* title = [self.dataSource titleForIndexPath:previewIndexPath];
    self.previewingTitle = title;
    [[PiwikTracker sharedInstance] wmf_logActionPreviewForTitle:title fromSource:self];
    return [[WMFArticleContainerViewController alloc] initWithArticleTitle:title
                                                                 dataStore:[self dataStore]
                                                           discoveryMethod:self.dataSource.discoveryMethod];
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(WMFArticleContainerViewController*)viewControllerToCommit {
    [[PiwikTracker sharedInstance] wmf_logActionPreviewCommittedForTitle:self.previewingTitle fromSource:self];
    self.previewingTitle = nil;
    if (self.delegate) {
        [self.delegate didCommitToPreviewedArticleViewController:viewControllerToCommit sender:self];
    } else {
        [self wmf_pushArticleViewController:viewControllerToCommit];
    }
}

- (NSString*)analyticsName {
    return [self.dataSource analyticsName];
}

@end

@implementation WMFSelfSizingArticleListTableViewController

- (void)loadView {
    [super loadView];
    UITableView* tv = [[WMFIntrinsicSizeTableView alloc] initWithFrame:CGRectZero];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.delegate                                  = self;
    self.tableView                               = tv;
}

@end

NS_ASSUME_NONNULL_END