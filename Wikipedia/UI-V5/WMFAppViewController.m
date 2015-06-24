
#import "WMFAppViewController.h"
#import "SessionSingleton.h"
#import "WMFStyleManager.h"
#import "WMFSearchViewController.h"
#import "WMFArticleListCollectionViewController.h"
#import "DataMigrationProgressViewController.h"
#import "WMFSavedPagesDataSource.h"
#import "UIStoryboard+WMFExtensions.h"
#import <Masonry/Masonry.h>

@interface WMFAppViewController ()<WMFSearchViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIView* searchContainerView;
@property (strong, nonatomic) IBOutlet UIView* articleListContainerView;

@property (nonatomic, strong) IBOutlet UIView* splashView;
@property (nonatomic, strong) WMFArticleListCollectionViewController* listViewController;
@property (nonatomic, strong) WMFSearchViewController* searchViewController;

@property (nonatomic, strong) SessionSingleton* session;

@property (nonatomic, strong) MASConstraint* articleListVisibleConstraint;
@property (nonatomic, strong) MASConstraint* articleListMinimizedConstraint;

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
    [self updateListViewBasedOnSearchState:self.searchViewController.state];

    self.searchViewController.searchSite = [self.session searchSite];
    self.searchViewController.dataStore  = [self.session dataStore];
    self.listViewController.dataSource   = [[WMFSavedPagesDataSource alloc] initWithUserDataStore:[self userDataStore]];;
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
    if ([segue.destinationViewController isKindOfClass:[WMFArticleListCollectionViewController class]]) {
        self.listViewController = segue.destinationViewController;
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
            [self.articleListMinimizedConstraint uninstall];
            [self.articleListContainerView mas_makeConstraints:^(MASConstraintMaker* make) {
                self.articleListVisibleConstraint = make.top.equalTo(self.view.mas_top).with.offset(64.0);
            }];
            [self.view layoutIfNeeded];

            [self.listViewController setListMode:WMFArticleListModeNormal animated:YES completion:NULL];
        }
        break;
        case WMFSearchStateActive: {
            @weakify(self);
            [self.listViewController setListMode:WMFArticleListModeBottomStacked animated:YES completion:^{
                @strongify(self);
                [self.articleListVisibleConstraint uninstall];
                [self.articleListContainerView mas_makeConstraints:^(MASConstraintMaker* make) {
                    self.articleListMinimizedConstraint = make.top.equalTo(self.view.mas_bottom).with.offset(-50.0);
                }];
                [self.view layoutIfNeeded];
            }];
        }
        break;
    }
}

@end
