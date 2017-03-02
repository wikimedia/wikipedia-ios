#import "WMFArticleListDataSourceTableViewController.h"

#import "MWKDataStore.h"
#import "MWKArticle.h"

#import "SSDataSources.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "Wikipedia-Swift.h"

static const NSString *kvo_WMFArticleListDataSourceTableViewController_dataSource_urls = nil;

NS_ASSUME_NONNULL_BEGIN

@implementation WMFArticleListDataSourceTableViewController

#pragma mark - Tear Down

- (void)dealloc {
    [self unobserveArticleUpdates];
    self.dataSource = nil;
}

#pragma mark - Accessors

- (void)setDataSource:(SSBaseDataSource<WMFTitleListDataSource> *__nullable)dataSource {
    if (_dataSource == dataSource) {
        return;
    }

    _dataSource.tableView = nil;
    self.tableView.dataSource = nil;


    NSString *keyPath = WMF_SAFE_KEYPATH(_dataSource, urls);
    [(id)_dataSource removeObserver:self forKeyPath:keyPath context:&kvo_WMFArticleListDataSourceTableViewController_dataSource_urls];
    
    _dataSource = dataSource;

    [(id)_dataSource addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_WMFArticleListDataSourceTableViewController_dataSource_urls];
    
    //HACK: Need to check the window to see if we are on screen. http://stackoverflow.com/a/2777460/48311
    //isViewLoaded is not enough.
    if ([self isViewLoaded] && self.view.window) {
        if (_dataSource) {
            _dataSource.tableView = self.tableView;
        }
        [self.tableView wmf_scrollToTop:NO];
        [self.tableView reloadData];
    }

    [self updateEmptyAndDeleteState];
}

#pragma mark - Stay Fresh... yo

- (void)observeArticleUpdates {
    [self unobserveArticleUpdates];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleUpdatedWithNotification:) name:MWKArticleSavedNotification object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)articleUpdatedWithNotification:(NSNotification *)note {
    MWKArticle *article = note.userInfo[MWKArticleKey];
    [self updateEmptyAndDeleteState];
    [self refreshAnyVisibleCellsWhichAreShowingArticleURL:article.url];
}

- (void)refreshAnyVisibleCellsWhichAreShowingArticleURL:(NSURL *)url {
    NSArray *indexPathsToRefresh = [[self.tableView indexPathsForVisibleRows] bk_select:^BOOL(NSIndexPath *indexPath) {
        NSURL *otherURL = [self.dataSource urlForIndexPath:indexPath];
        return [url isEqual:otherURL];
    }];

    [self.dataSource reloadCellsAtIndexPaths:indexPathsToRefresh];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _dataSource.tableView = self.tableView;
    [self observeArticleUpdates];
}

- (void)viewWillAppear:(BOOL)animated {
    self.dataSource.tableView = self.tableView;
    [super viewWillAppear:animated];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.dataSource canDeleteItemAtIndexpath:indexPath]) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (BOOL)showsDeleteAllButton {
    return [self.dataSource respondsToSelector:@selector(deleteAll)];
}

- (void)deleteAll {
    if ([self.dataSource respondsToSelector:@selector(deleteAll)]) {
        [self.dataSource deleteAll];
    }
}

- (NSInteger)numberOfItems {
    return [self.dataSource titleCount];
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSource urlForIndexPath:indexPath];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey,id> *)change context:(nullable void *)context {
    if (context == &kvo_WMFArticleListDataSourceTableViewController_dataSource_urls) {
        [self updateEmptyAndDeleteState];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end

NS_ASSUME_NONNULL_END
