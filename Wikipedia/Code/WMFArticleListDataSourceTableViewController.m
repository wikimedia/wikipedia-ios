
#import "WMFArticleListDataSourceTableViewController.h"

#import <BlocksKit/BlocksKit+UIKit.h>

#import "MWKDataStore.h"
#import "MWKArticle.h"

#import <SSDataSources/SSDataSources.h>

#import "UIScrollView+WMFContentOffsetUtils.h"
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFArticleListDataSourceTableViewController

#pragma mark - Tear Down

- (void)dealloc {
    [self unobserveArticleUpdates];
    // NOTE(bgerstle): must check if dataSource was set to prevent creation of KVOControllerNonRetaining during dealloc
    // happens during tests, creating KVOControllerNonRetaining during dealloc attempts to create weak ref, causing crash
    if (self.dataSource) {
        [self.KVOControllerNonRetaining unobserve:self.dataSource keyPath:WMF_SAFE_KEYPATH(self.dataSource, urls)];
    }
}

#pragma mark - Accessors

- (void)setDataSource:(SSBaseDataSource<WMFTitleListDataSource>* __nullable)dataSource {
    if (_dataSource == dataSource) {
        return;
    }

    _dataSource.tableView     = nil;
    self.tableView.dataSource = nil;

    [self.KVOControllerNonRetaining unobserve:self.dataSource keyPath:WMF_SAFE_KEYPATH(self.dataSource, urls)];

    _dataSource = dataSource;

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
    [self.KVOControllerNonRetaining observe:self.dataSource
                                    keyPath:WMF_SAFE_KEYPATH(self.dataSource, urls)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WMFArticleListDataSourceTableViewController* observer,
                                              SSBaseDataSource < WMFTitleListDataSource > * object,
                                              NSDictionary* change) {
        [observer updateEmptyAndDeleteState];
    }];
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"%@ dataSourceClass: %@", self, [self.dataSource class]];
}

#pragma mark - Stay Fresh... yo

- (void)observeArticleUpdates {
    [self unobserveArticleUpdates];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleUpdatedWithNotification:) name:MWKArticleSavedNotification object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)articleUpdatedWithNotification:(NSNotification*)note {
    MWKArticle* article = note.userInfo[MWKArticleKey];
    [self updateEmptyAndDeleteState];
    [self refreshAnyVisibleCellsWhichAreShowingArticleURL:article.url];
}

- (void)refreshAnyVisibleCellsWhichAreShowingArticleURL:(NSURL*)url {
    NSArray* indexPathsToRefresh = [[self.tableView indexPathsForVisibleRows] bk_select:^BOOL (NSIndexPath* indexPath) {
        NSURL* otherURL = [self.dataSource urlForIndexPath:indexPath];
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
    NSParameterAssert(self.dataSource);
    self.dataSource.tableView = self.tableView;
    [super viewWillAppear:animated];
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
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

- (NSURL*)urlAtIndexPath:(NSIndexPath*)indexPath {
    return [self.dataSource urlForIndexPath:indexPath];
}

@end

NS_ASSUME_NONNULL_END