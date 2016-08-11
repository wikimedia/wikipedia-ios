#import "WMFArticleFooterMenuViewController.h"
#import "WMFIntrinsicSizeTableView.h"
#import "MWKArticle.h"
#import <SSDataSources/SSDataSources.h>
#import "WMFArticleListDataSourceTableViewController.h"
#import "WMFArticlePreviewFetcher.h"
#import "WMFArticleFooterMenuItem.h"
#import "PageHistoryViewController.h"
#import "WMFLanguagesViewController.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageLink.h"
#import "WMFArticleViewController.h"
#import "WMFDisambiguationPagesViewController.h"
#import "WMFPageIssuesViewController.h"
#import "WMFArticleFooterMenuDataSource.h"
#import "WMFArticleFooterMenuCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UINavigationController+WMFHideEmptyToolbar.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "UIViewController+WMFStoryboardUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleFooterMenuViewController () <UITableViewDelegate, WMFLanguagesViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) WMFArticleFooterMenuDataSource* footerDataSource;

@property (nonatomic, strong) IBOutlet WMFIntrinsicSizeTableView* tableView;

@property (nonatomic, weak, readwrite) id<WMFArticleListTableViewControllerDelegate> similarPagesDelegate;

@end

@implementation WMFArticleFooterMenuViewController

- (instancetype)initWithArticle:(MWKArticle*)article similarPagesListDelegate:(id<WMFArticleListTableViewControllerDelegate>)delegate {
    NSParameterAssert(article);
    NSParameterAssert(delegate);
    self = [super init];
    if (self) {
        self.footerDataSource     = [[WMFArticleFooterMenuDataSource alloc] initWithArticle:self.article];
        self.similarPagesDelegate = delegate;
    }
    return self;
}

- (void)setArticle:(MWKArticle*)article {
    if (WMF_EQUAL(self.article, isEqualToArticle:, article)) {
        return;
    }
    self.footerDataSource.article = article;
}

- (MWKArticle*)article {
    return self.footerDataSource.article;
}

#pragma mark - Accessors

- (MWKDataStore*)dataStore {
    return self.article.dataStore;
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    // HAX: collapses space between grouped table sections
    return 0.00001;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    // HAX: collapses space between grouped table sections
    return 0.00001;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticleFooterMenuCell wmf_classNib] forCellReuseIdentifier:[WMFArticleFooterMenuCell identifier]];

    NSAssert(self.tableView.style == UITableViewStyleGrouped, @"Use grouped UITableView layout so we get separator above first cell and below last cell without having to implement any special logic");

    self.tableView.estimatedRowHeight = 52.0;
    self.tableView.rowHeight          = UITableViewAutomaticDimension;

    self.footerDataSource.tableView = self.tableView;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    switch ([(WMFArticleFooterMenuItem*)[self.footerDataSource itemAtIndexPath:indexPath] type]) {
        case WMFArticleFooterMenuItemTypeLanguages:
            [self showLanguages];
            break;
        case WMFArticleFooterMenuItemTypeLastEdited:
            [self showEditHistory];
            break;
        case WMFArticleFooterMenuItemTypePageIssues:
            [self showPageIssues];
            break;
        case WMFArticleFooterMenuItemTypeDisambiguation:
            [self showDisambiguationItems];
            break;
    }
}

#pragma mark - Subview Actions

- (void)showDisambiguationItems {
    WMFDisambiguationPagesViewController* articleListVC = [[WMFDisambiguationPagesViewController alloc] initWithArticle:self.article dataStore:self.dataStore];
    articleListVC.delegate = self.similarPagesDelegate;
    articleListVC.title    = MWLocalizedString(@"page-similar-titles", nil);
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:articleListVC];
    navController.delegate = self;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)navigationController:(UINavigationController*)navigationController
      willShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated {
    [navigationController wmf_hideToolbarIfViewControllerHasNoToolbarItems:viewController];
}

- (void)showEditHistory {
    PageHistoryViewController* editHistoryVC = [PageHistoryViewController wmf_initialViewControllerFromClassStoryboard];
    editHistoryVC.article = self.article;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:editHistoryVC] animated:YES completion:nil];
}

- (void)showLanguages {
    WMFArticleLanguagesViewController* languagesVC = [WMFArticleLanguagesViewController articleLanguagesViewControllerWithArticleURL:self.article.url];
    languagesVC.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languagesController:(WMFArticleLanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [self dismissViewControllerAnimated:YES completion:^{
        WMFArticleViewController* articleContainerVC =
            [[WMFArticleViewController alloc] initWithArticleURL:language.articleURL
                                                       dataStore:self.dataStore];
        [self.navigationController pushViewController:articleContainerVC animated:YES];
    }];
}

- (void)showPageIssues {
    WMFPageIssuesViewController* issuesVC = [[WMFPageIssuesViewController alloc] initWithStyle:UITableViewStyleGrouped];
    issuesVC.dataSource = [[SSArrayDataSource alloc] initWithItems:self.article.pageIssues];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:issuesVC] animated:YES completion:nil];
}

@end

NS_ASSUME_NONNULL_END
