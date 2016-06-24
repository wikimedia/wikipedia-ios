
#import "WMFAppViewController.h"
#import "Wikipedia-Swift.h"

// Frameworks
#import <Masonry/Masonry.h>
#import <Tweaks/FBTweakInline.h>
#import "PiwikTracker+WMFExtensions.h"

// Utility
#import "NSDate+Utilities.h"
#import "MWKDataHousekeeping.h"
#import "NSUserActivity+WMFExtensions.h"
// Networking
#import "SavedArticlesFetcher.h"
#import "SessionSingleton.h"
#import "AssetsFileFetcher.h"
#import "QueuesSingleton.h"

// Model
#import "MediaWikiKit.h"
#import "MWKSearchResult.h"
#import "MWKLanguageLinkController.h"

// Views
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "UIFont+WMFStyle.h"
#import "WMFStyleManager.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"

// View Controllers
#import "WMFExploreViewController.h"
#import "WMFSearchViewController.h"
#import "WMFArticleListTableViewController.h"
#import "DataMigrationProgressViewController.h"
#import "WMFWelcomeViewController.h"
#import "WMFArticleBrowserViewController.h"
#import "WMFNearbyListViewController.h"
#import "UIViewController+WMFSearch.h"
#import "UINavigationController+WMFHideEmptyToolbar.h"

#import "AppDelegate.h"
#import "WMFRandomSectionController.h"
#import "WMFNearbySectionController.h"
#import "WMFRandomArticleFetcher.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"

/**
 *  Enums for each tab in the main tab bar.
 *
 *  @warning Be sure to update `WMFAppTabCount` when these enums change, and always initialize the first enum to 0.
 *
 *  @see WMFAppTabCount
 */
typedef NS_ENUM (NSUInteger, WMFAppTabType){
    WMFAppTabTypeExplore = 0,
    WMFAppTabTypeSaved,
    WMFAppTabTypeRecent
};

/**
 *  Number of tabs in the main tab bar.
 *
 *  @warning Kept as a separate constant to prevent switch statements from being considered inexhaustive. This means we
 *           need to make sure it's manually kept in sync by ensuring:
 *              - The tab enum we increment is the last one
 *              - The first tab enum is initialized to 0
 *
 *  @see WMFAppTabType
 */
static NSUInteger const WMFAppTabCount = WMFAppTabTypeRecent + 1;

static NSTimeInterval const WMFTimeBeforeRefreshingExploreScreen = 24 * 60 * 60;

@interface WMFAppViewController ()<UITabBarControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) IBOutlet UIView* splashView;
@property (nonatomic, strong) UITabBarController* rootTabBarController;

@property (nonatomic, strong, readonly) WMFExploreViewController* exploreViewController;
@property (nonatomic, strong, readonly) WMFArticleListTableViewController* savedArticlesViewController;
@property (nonatomic, strong, readonly) WMFArticleListTableViewController* recentArticlesViewController;

@property (nonatomic, strong) WMFLegacyImageDataMigration* imageMigration;
@property (nonatomic, strong) SavedArticlesFetcher* savedArticlesFetcher;
@property (nonatomic, strong) WMFRandomArticleFetcher* randomFetcher;
@property (nonatomic, strong) SessionSingleton* session;
@property (nonatomic, strong) WMFSavedPageSpotlightManager* spotlightManager;

@property (nonatomic) BOOL isPresentingOnboarding;

@property (nonatomic, strong) NSUserActivity* unprocessedUserActivity;
@property (nonatomic, strong) UIApplicationShortcutItem* unprocessedShortcutItem;


/// Use @c rootTabBarController instead.
- (UITabBarController*)tabBarController NS_UNAVAILABLE;

@end

@implementation WMFAppViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isPresentingOnboarding {
    return [self.presentedViewController isKindOfClass:[WMFWelcomeViewController class]];
}

- (BOOL)uiIsLoaded {
    return _rootTabBarController != nil;
}

#pragma mark - Setup

- (void)loadMainUI {
    if ([self uiIsLoaded]) {
        return;
    }
    UITabBarController* tabBar = [[UIStoryboard storyboardWithName:@"WMFTabBarUI" bundle:nil] instantiateInitialViewController];
    [self addChildViewController:tabBar];
    [self.view addSubview:tabBar.view];
    [tabBar.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.top.and.bottom.and.leading.and.trailing.equalTo(self.view);
    }];
    [tabBar didMoveToParentViewController:self];
    self.rootTabBarController = tabBar;
    [self configureTabController];
    [self configureExploreViewController];
    [self configureArticleListController:self.savedArticlesViewController];
    [self configureArticleListController:self.recentArticlesViewController];
    [[self class] wmf_setSearchButtonDataStore:self.dataStore];
}

- (void)configureTabController {
    self.rootTabBarController.delegate = self;

    for (WMFAppTabType i = 0; i < WMFAppTabCount; i++) {
        UINavigationController* navigationController = [self navigationControllerForTab:i];
        navigationController.delegate = self;
    }
}

- (void)configureExploreViewController {
    [self.exploreViewController setDataStore:[self dataStore]];
}

- (void)configureArticleListController:(WMFArticleListTableViewController*)controller {
    controller.dataStore = self.session.dataStore;
}

#pragma mark - Notifications

- (void)appWillEnterForegroundWithNotification:(NSNotification*)note {
    self.unprocessedUserActivity = nil;
    self.unprocessedShortcutItem = nil;
    [self resumeApp];
}

- (void)appDidEnterBackgroundWithNotification:(NSNotification*)note {
    [self pauseApp];
}

#pragma mark - Launch

+ (WMFAppViewController*)initialAppViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard storyboardWithName:NSStringFromClass([WMFAppViewController class]) bundle:nil] instantiateInitialViewController];
}

- (void)launchAppInWindow:(UIWindow*)window {
    WMFStyleManager* manager = [WMFStyleManager new];
    [manager applyStyleToWindow:window];
    [WMFStyleManager setSharedStyleManager:manager];

    [window setRootViewController:self];
    [window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundWithNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundWithNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [self showSplashView];

    @weakify(self)
    [self runDataMigrationIfNeededWithCompletion :^{
        @strongify(self)
        [self.imageMigration setupAndStart];
        [self.savedArticlesFetcher fetchAndObserveSavedPageList];
        if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
            self.spotlightManager = [[WMFSavedPageSpotlightManager alloc] initWithDataStore:self.session.dataStore];
        }
        [self presentOnboardingIfNeededWithCompletion:^(BOOL didShowOnboarding) {
            @strongify(self)
            [self loadMainUI];
            [self hideSplashViewAnimated:!didShowOnboarding];
            [self resumeApp];
            [[PiwikTracker wmf_configuredInstance] wmf_logView:[self rootViewControllerForTab:WMFAppTabTypeExplore]];
        }];
    }];
}

#pragma mark - Start/Pause/Resume App

- (void)resumeApp {
    if (self.isPresentingOnboarding) {
        return;
    }

    [self.session autoLogin];

    if (self.unprocessedUserActivity) {
        [self processUserActivity:self.unprocessedUserActivity];
    } else if (self.unprocessedShortcutItem) {
        [self processShortcutItem:self.unprocessedShortcutItem completion:NULL];
    } else if ([self shouldShowLastReadArticleOnLaunch]) {
        [self showLastReadArticleAnimated:YES];
    } else if ([self shouldShowExploreScreenOnLaunch]) {
        [self showExplore];
    }

    if (FBTweakValue(@"Alerts", @"General", @"Show error on launch", NO)) {
        [[WMFAlertManager sharedInstance] showErrorAlert:[NSError errorWithDomain:@"WMFTestDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: @"There was an error"}] sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show warning on launch", NO)) {
        [[WMFAlertManager sharedInstance] showWarningAlert:@"You have been warned" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show success on launch", NO)) {
        [[WMFAlertManager sharedInstance] showSuccessAlert:@"You are successful" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show message on launch", NO)) {
        [[WMFAlertManager sharedInstance] showAlert:@"You have been notified" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
}

- (void)pauseApp {
    [[WMFImageController sharedInstance] clearMemoryCache];
    [self downloadAssetsFilesIfNecessary];
    [self performHousekeeping];
    [[[SessionSingleton sharedInstance] dataStore] clearMemoryCache];
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [[WMFImageController sharedInstance] clearMemoryCache];
    [[[SessionSingleton sharedInstance] dataStore] clearMemoryCache];
}

#pragma mark - Shortcut

- (BOOL)canProcessShortcutItem:(UIApplicationShortcutItem*)item {
    if (!item) {
        return NO;
    }
    if ([item.type isEqualToString:WMFIconShortcutTypeSearch]) {
        return YES;
    } else if ([item.type isEqualToString:WMFIconShortcutTypeRandom]) {
        return YES;
    } else if ([item.type isEqualToString:WMFIconShortcutTypeNearby]) {
        return YES;
    } else if ([item.type isEqualToString:WMFIconShortcutTypeContinueReading]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)processShortcutItem:(UIApplicationShortcutItem*)item completion:(void (^)(BOOL))completion {
    if (![self canProcessShortcutItem:item]) {
        if (completion) {
            completion(NO);
        }
        return;
    }

    if (![self uiIsLoaded]) {
        self.unprocessedShortcutItem = item;
        if (completion) {
            completion(YES);
        }
        return;
    }
    self.unprocessedShortcutItem = nil;

    if ([item.type isEqualToString:WMFIconShortcutTypeSearch]) {
        [self showSearchAnimated:YES];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeRandom]) {
        [self showRandomArticleAnimated:YES];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeNearby]) {
        [self showNearbyListAnimated:YES];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeContinueReading]) {
        [self showLastReadArticleAnimated:YES];
    }
    if (completion) {
        completion(YES);
    }
}

#pragma mark - NSUserActivity

- (BOOL)canProcessUserActivity:(NSUserActivity*)activity {
    if (!activity) {
        return NO;
    }
    switch ([activity wmf_type]) {
        case WMFUserActivityTypeExplore:
        case WMFUserActivityTypeSavedPages:
        case WMFUserActivityTypeHistory:
        case WMFUserActivityTypeSearch:
        case WMFUserActivityTypeSettings:
            return YES;
        case WMFUserActivityTypeSearchResults:
            if ([activity wmf_searchTerm]) {
                return YES;
            } else {
                return NO;
            }
            break;
        case WMFUserActivityTypeArticle: {
            if (![[MWKTitle alloc] initWithURL:activity.webpageURL]) {
                return NO;
            } else {
                return YES;
            }
        }
        break;
        default:
            return NO;
            break;
    }
}

- (BOOL)processUserActivity:(NSUserActivity*)activity {
    if (![self canProcessUserActivity:activity]) {
        return NO;
    }
    if (![self uiIsLoaded]) {
        self.unprocessedUserActivity = activity;
        return YES;
    }
    self.unprocessedUserActivity = nil;
    [self dismissViewControllerAnimated:NO completion:NULL];
    switch ([activity wmf_type]) {
        case WMFUserActivityTypeExplore:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            break;
        case WMFUserActivityTypeSavedPages:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeSaved];
            [[self navigationControllerForTab:WMFAppTabTypeSaved] popToRootViewControllerAnimated:NO];
            break;
        case WMFUserActivityTypeHistory:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeRecent];
            [[self navigationControllerForTab:WMFAppTabTypeRecent] popToRootViewControllerAnimated:NO];
            break;
        case WMFUserActivityTypeSearch:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            [[self rootViewControllerForTab:WMFAppTabTypeExplore] wmf_showSearchAnimated:NO];
            break;
        case WMFUserActivityTypeSearchResults:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            [[self rootViewControllerForTab:WMFAppTabTypeExplore] wmf_showSearchAnimated:NO];
            [[UIViewController wmf_sharedSearchViewController] setSearchTerm:[activity wmf_searchTerm]];
            break;
        case WMFUserActivityTypeArticle: {
            MWKTitle* title = [[MWKTitle alloc] initWithURL:activity.webpageURL];
            if (!title) {
                return NO;
            }
            [self showArticleForTitle:title animated:NO];
        }
        break;
        case WMFUserActivityTypeSettings:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            [self.exploreViewController showSettings];
            break;
        default:
            return NO;
            break;
    }


    return YES;
}

#pragma mark - Utilities

- (void)showArticleForTitle:(MWKTitle*)title animated:(BOOL)animated {
    if (!title) {
        return;
    }
    if ([[self onscreenTitle] isEqualToTitle:title]) {
        return;
    }
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    [[self exploreViewController] wmf_pushArticleWithTitle:title dataStore:self.session.dataStore restoreScrollPosition:YES animated:animated];
}

- (BOOL)shouldShowExploreScreenOnLaunch {
    NSDate* resignActiveDate = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeRefreshingExploreScreen) {
        return YES;
    }
    return NO;
}

- (BOOL)exploreViewControllerIsDisplayingContent {
    return [self navigationControllerForTab:WMFAppTabTypeExplore].viewControllers.count > 1;
}

- (BOOL)articleBrowserIsBeingDisplayed {
    UINavigationController* navVC = [self navigationControllerForTab:self.rootTabBarController.selectedIndex];
    if (navVC.presentedViewController && [navVC.presentedViewController isKindOfClass:[WMFArticleBrowserViewController class]]) {
        return YES;
    }

    return NO;
}

- (MWKTitle*)onscreenTitle {
    UINavigationController* navVC = [self navigationControllerForTab:self.rootTabBarController.selectedIndex];
    if ([navVC.topViewController isKindOfClass:[WMFArticleViewController class]]) {
        return ((WMFArticleViewController*)navVC.topViewController).articleTitle;
    }

    if (navVC.presentedViewController && [navVC.presentedViewController isKindOfClass:[WMFArticleBrowserViewController class]]) {
        WMFArticleBrowserViewController* vc = (id)navVC.presentedViewController;
        return [vc titleOfCurrentArticle];
    }
    return nil;
}

- (UINavigationController*)navigationControllerForTab:(WMFAppTabType)tab {
    return (UINavigationController*)[self.rootTabBarController viewControllers][tab];
}

- (UIViewController<WMFAnalyticsViewNameProviding>*)rootViewControllerForTab:(WMFAppTabType)tab {
    return [[[self navigationControllerForTab:tab] viewControllers] firstObject];
}

#pragma mark - Accessors

- (WMFLegacyImageDataMigration*)imageMigration {
    if (!_imageMigration) {
        _imageMigration = [[WMFLegacyImageDataMigration alloc]
                           initWithImageController:[WMFImageController sharedInstance]
                                   legacyDataStore:[MWKDataStore new]];
    }
    return _imageMigration;
}

- (SavedArticlesFetcher*)savedArticlesFetcher {
    if (!_savedArticlesFetcher) {
        _savedArticlesFetcher =
            [[SavedArticlesFetcher alloc] initWithSavedPageList:[[[SessionSingleton sharedInstance] userDataStore] savedPageList]];
    }
    return _savedArticlesFetcher;
}

- (WMFRandomArticleFetcher*)randomFetcher {
    if (_randomFetcher == nil) {
        _randomFetcher = [[WMFRandomArticleFetcher alloc] init];
    }
    return _randomFetcher;
}

- (SessionSingleton*)session {
    if (!_session) {
        _session = [SessionSingleton sharedInstance];
    }

    return _session;
}

- (MWKDataStore*)dataStore {
    return self.session.dataStore;
}

- (MWKUserDataStore*)userDataStore {
    return self.session.userDataStore;
}

- (WMFExploreViewController*)exploreViewController {
    return (WMFExploreViewController*)[self rootViewControllerForTab:WMFAppTabTypeExplore];
}

- (WMFArticleListTableViewController*)savedArticlesViewController {
    return (WMFArticleListTableViewController*)[self rootViewControllerForTab:WMFAppTabTypeSaved];
}

- (WMFArticleListTableViewController*)recentArticlesViewController {
    return (WMFArticleListTableViewController*)[self rootViewControllerForTab:WMFAppTabTypeRecent];
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotate {
    if (self.rootTabBarController) {
        return [self.rootTabBarController shouldAutorotate];
    } else {
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.rootTabBarController) {
        return [self.rootTabBarController supportedInterfaceOrientations];
    } else {
        return [self wmf_orientationMaskPortraitiPhoneAnyiPad];
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.rootTabBarController) {
        return [self.rootTabBarController preferredInterfaceOrientationForPresentation];
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

#pragma mark - Onboarding

static NSString* const WMFDidShowOnboarding = @"DidShowOnboarding5.0";

- (BOOL)shouldShowOnboarding {
    if (FBTweakValue(@"Welcome", @"General", @"Show on launch (requires force quit)", NO)
        || [[NSProcessInfo processInfo] environment][@"WMFShowWelcomeView"].boolValue) {
        return YES;
    }
    NSNumber* didShow = [[NSUserDefaults standardUserDefaults] objectForKey:WMFDidShowOnboarding];
    return !didShow.boolValue;
}

- (void)setDidShowOnboarding {
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:WMFDidShowOnboarding];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)presentOnboardingIfNeededWithCompletion:(void (^)(BOOL didShowOnboarding))completion {
    if ([self shouldShowOnboarding]) {
        WMFWelcomeViewController* vc = [WMFWelcomeViewController welcomeViewControllerFromDefaultStoryBoard];
        vc.completionBlock = ^{
            [self setDidShowOnboarding];
            if (completion) {
                completion(YES);
            }
        };
        [self presentViewController:vc animated:NO completion:NULL];
    } else {
        if (completion) {
            completion(NO);
        }
    }
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

#pragma mark - Explore VC

- (void)showExplore {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
}

#pragma mark - Last Read Article

- (BOOL)shouldShowLastReadArticleOnLaunch {
    MWKTitle* lastRead = [[NSUserDefaults standardUserDefaults] wmf_openArticleTitle];
    if (!lastRead) {
        return NO;
    }

    if (FBTweakValue(@"Last Open Article", @"General", @"Restore on Launch", YES)) {
        return YES;
    }

    NSDate* resignActiveDate = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) < WMFTimeBeforeRefreshingExploreScreen) {
        if (![self exploreViewControllerIsDisplayingContent] && [self.rootTabBarController selectedIndex] == WMFAppTabTypeExplore) {
            return YES;
        }
    }

    return NO;
}

- (void)showLastReadArticleAnimated:(BOOL)animated {
    MWKTitle* lastRead = [[NSUserDefaults standardUserDefaults] wmf_openArticleTitle];
    [self showArticleForTitle:lastRead animated:animated];
}

- (WMFArticleBrowserViewController*)currentlyDisplayedArticleBrowser {
    UINavigationController* navVC = [self navigationControllerForTab:self.rootTabBarController.selectedIndex];
    if (navVC.presentedViewController && [navVC.presentedViewController isKindOfClass:[WMFArticleBrowserViewController class]]) {
        WMFArticleBrowserViewController* vc = (id)navVC.presentedViewController;
        return vc;
    }
    return nil;
}

#pragma mark - Show Search

- (void)showSearchAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController* exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }
    [self.exploreViewController wmf_showSearchAnimated:animated];
}

#pragma mark - App Shortcuts

- (void)showRandomArticleAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController* exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }
    MWKSite* site = [[[MWKLanguageLinkController sharedInstance] appLanguage] site];
    [self.randomFetcher fetchRandomArticleWithSite:site].then(^(MWKSearchResult* result){
        MWKTitle* title = [site titleWithString:result.displayTitle];
        [[self exploreViewController] wmf_pushArticleWithTitle:title dataStore:self.session.dataStore animated:YES];
    }).catch(^(NSError* error){
        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    });
}

- (void)showNearbyListAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController* exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }
    [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
    MWKSite* site                   = [[[MWKLanguageLinkController sharedInstance] appLanguage] site];
    WMFNearbyListViewController* vc = [[WMFNearbyListViewController alloc] initWithSearchSite:site dataStore:self.dataStore];
    [[self navigationControllerForTab:WMFAppTabTypeExplore] pushViewController:vc animated:animated];
}

#pragma mark - House Keeping

- (void)performHousekeeping {
    MWKDataHousekeeping* dataHouseKeeping = [[MWKDataHousekeeping alloc] init];
    [dataHouseKeeping performHouseKeeping];
}

#pragma mark - Download Assets

- (void)downloadAssetsFilesIfNecessary {
    // Sync config/ios.json at most once per day.
    [[QueuesSingleton sharedInstance].assetsFetchManager wmf_cancelAllTasksWithCompletionHandler:^{
        (void)[[AssetsFileFetcher alloc] initAndFetchAssetsFileOfType:WMFAssetsFileTypeConfig
                                                          withManager:[QueuesSingleton sharedInstance].assetsFetchManager
                                                               maxAge:kWMFMaxAgeDefault];
    }];
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

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController {
    [self wmf_hideKeyboard];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController*)navigationController
      willShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated {
    [navigationController wmf_hideToolbarIfViewControllerHasNoToolbarItems:viewController];
}

@end
