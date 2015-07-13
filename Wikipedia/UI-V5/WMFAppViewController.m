
#import "WMFAppViewController.h"
#import "SessionSingleton.h"
#import "WMFStyleManager.h"
#import "WMFSearchViewController.h"
#import "WMFArticleListCollectionViewController.h"
#import "DataMigrationProgressViewController.h"
#import "WMFSavedPagesDataSource.h"
#import "UIStoryboard+WMFExtensions.h"
#import "UITabBarController+WMFExtensions.h"
#import <Masonry/Masonry.h>


@interface WMFAppViewController ()<WMFSearchViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIView* searchContainerView;
@property (strong, nonatomic) IBOutlet UIView* tabControllerContainerView;

@property (nonatomic, strong) IBOutlet UIView* splashView;

@property (nonatomic, strong) UITabBarController* tabBarController;
@property (nonatomic, strong, readonly) WMFArticleListCollectionViewController* savedArticlesViewController;
@property (nonatomic, strong) WMFSearchViewController* searchViewController;

@property (nonatomic, strong) SessionSingleton* session;

@end

@implementation WMFAppViewController

- (SessionSingleton*)session {
    if (!_session) {
        _session = [SessionSingleton sharedInstance];
    }

    return _session;
}

#pragma mark - Setup

+ (WMFAppViewController*)initialAppViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard wmf_appRootStoryBoard] instantiateInitialViewController];
}

- (void)launchAppInWindow:(UIWindow*)window {
    WMFStyleManager* manager = [WMFStyleManager new];
    [manager applyStyleToWindow:window];
    [WMFStyleManager setSharedStyleManager:manager];

    [window setRootViewController:self];
    [window makeKeyAndVisible];
}

- (void)loadMainUI {
    self.searchViewController.searchSite    = [self.session searchSite];
    self.searchViewController.dataStore     = self.session.dataStore;
    self.searchViewController.userDataStore = self.session.userDataStore;

    self.savedArticlesViewController.dataStore  = self.session.dataStore;
    self.savedArticlesViewController.savedPages = self.session.userDataStore.savedPageList;
    self.savedArticlesViewController.dataSource = [[WMFSavedPagesDataSource alloc] initWithSavedPagesList:[self userDataStore].savedPageList];

    [self updateListViewBasedOnSearchState:self.searchViewController.state];
}

- (void)resumeApp {
    //TODO: restore any UI, show Today
}

#pragma mark - Accessors

- (MWKDataStore*)dataStore {
    return self.session.dataStore;
}

- (MWKUserDataStore*)userDataStore {
    return self.session.userDataStore;
}

- (WMFArticleListCollectionViewController*)savedArticlesViewController {
    return [[self.tabBarController viewControllers] bk_match:^BOOL (UIViewController* obj) {
        return [obj isKindOfClass:[WMFArticleListCollectionViewController class]];
    }];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self showSplashView];

    [self runDataMigrationIfNeededWithCompletion:^{
        [self hideSplashViewAnimated:YES];
        [self loadMainUI];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WMFSearchViewController class]]) {
        self.searchViewController          = segue.destinationViewController;
        self.searchViewController.delegate = self;
    }
    if ([segue.destinationViewController isKindOfClass:[UITabBarController class]]) {
        self.tabBarController = segue.destinationViewController;
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Splash

- (void)showSplashView {
    self.splashView.hidden          = NO;
    self.splashView.layer.transform = CATransform3DIdentity;
    self.splashView.alpha           = 1.0;
}

- (void)hideSplashViewAnimated:(BOOL)animated {
    NSTimeInterval duration = animated ? 0.3 : 0.0;

    [UIView animateWithDuration:duration animations:^{
        self.splashView.layer.transform = CATransform3DMakeScale(10.0f, 10.0f, 1.0f);
        self.splashView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.splashView.hidden = YES;
        self.splashView.layer.transform = CATransform3DIdentity;
    }];
}

- (BOOL)isShowingSplashView {
    return self.splashView.hidden == NO;
}

#pragma mark - Migration

- (void)runDataMigrationIfNeededWithCompletion:(dispatch_block_t)completion {
    DataMigrationProgressViewController* migrationVC = [[DataMigrationProgressViewController alloc] init];
    [migrationVC removeOldDataBackupIfNeeded];

    if (![migrationVC needsMigration]) {
        if (completion) {
            completion();
        }
        return;
    }

    [self presentViewController:migrationVC animated:YES completion:^{
        [migrationVC runMigrationWithCompletion:^(BOOL migrationCompleted) {
            [migrationVC dismissViewControllerAnimated:YES completion:NULL];
            if (completion) {
                completion();
            }
        }];
    }];
}

#pragma mark - WMFSearchViewControllerDelegate

- (void)searchController:(WMFSearchViewController*)controller searchStateDidChange:(WMFSearchState)state {
    [self updateListViewBasedOnSearchState:state];
}

- (void)updateListViewBasedOnSearchState:(WMFSearchState)state {
    switch (state) {
        case WMFSearchStateInactive: {
            self.tabBarController.view.hidden                      = NO;
            self.tabControllerContainerView.userInteractionEnabled = YES;
            [self.savedArticlesViewController setListMode:WMFArticleListModeNormal animated:YES completion:NULL];
            [self.tabBarController wmf_setTabBarVisible:YES animated:YES completion:NULL];
        }
        break;
        case WMFSearchStateActive: {
            [self.savedArticlesViewController setListMode:WMFArticleListModeOffScreen animated:YES completion:NULL];
            @weakify(self);
            [self.tabBarController wmf_setTabBarVisible:NO animated:YES completion:^{
                @strongify(self);
                self.tabBarController.view.hidden = YES;
                self.tabControllerContainerView.userInteractionEnabled = NO;
            }];
        }
        break;
    }
}

@end
