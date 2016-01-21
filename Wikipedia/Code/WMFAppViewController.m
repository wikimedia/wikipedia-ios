
#import "WMFAppViewController.h"
#import "Wikipedia-Swift.h"

// Frameworks
@import Masonry;
#import <Tweaks/FBTweakInline.h>
#import "PiwikTracker+WMFExtensions.h"

//Utility
#import "NSDate+Utilities.h"
#import "MWKDataHousekeeping.h"

// Networking
#import "SavedArticlesFetcher.h"
#import "SessionSingleton.h"
#import "AssetsFileFetcher.h"
#import "QueuesSingleton.h"

// Model
#import "MediaWikiKit.h"
#import "MWKSearchResult.h"

// Views
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "UIFont+WMFStyle.h"
#import "NSString+WMFGlyphs.h"
#import "WMFStyleManager.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"

// View Controllers
#import "WMFExploreViewController.h"
#import "WMFSearchViewController.h"
#import "WMFArticleListTableViewController.h"
#import "DataMigrationProgressViewController.h"
#import "WMFWelcomeViewController.h"
#import "WMFArticleContainerViewController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFLocationSearchListViewController.h"
#import "UIViewController+WMFSearch.h"

#import "AppDelegate.h"
#import "WMFRandomSectionController.h"
#import "WMFNearbySectionController.h"
#import "WMFRandomArticleFetcher.h"

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

static dispatch_once_t launchToken;

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

@property (nonatomic, strong) UIApplicationShortcutItem* shortcutItemSelectedAtLaunch;
@property (nonatomic, strong) void (^ shortcutCompletion)(BOOL succeeded);

@property (nonatomic) BOOL isPresentingOnboarding;

@end

@implementation WMFAppViewController

- (BOOL)isPresentingOnboarding {
    return [self.presentedViewController isKindOfClass:[WMFWelcomeViewController class]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)loadMainUI {
    if (self.rootTabBarController) {
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
}

- (void)configureTabController {
    self.rootTabBarController.delegate = self;

    for (WMFAppTabType i = 0; i < WMFAppTabCount; i++) {
        UINavigationController* navigationController = [self navigationControllerForTab:i];
        navigationController.delegate = self;
    }
}

- (void)configureExploreViewController {
    self.exploreViewController.searchSite  = [self.session searchSite];
    self.exploreViewController.dataStore   = self.session.dataStore;
    self.exploreViewController.savedPages  = self.session.userDataStore.savedPageList;
    self.exploreViewController.recentPages = self.session.userDataStore.historyList;
}

- (void)configureArticleListController:(WMFArticleListTableViewController*)controller {
    controller.dataStore = self.session.dataStore;
}

#pragma mark - Notifications

- (void)appDidBecomeActiveWithNotification:(NSNotification*)note {
    [self resumeApp];
}

- (void)appWillResignActiveWithNotification:(NSNotification*)note {
    [self pauseApp];
}

#pragma mark - Public

+ (WMFAppViewController*)initialAppViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard storyboardWithName:NSStringFromClass([WMFAppViewController class]) bundle:nil] instantiateInitialViewController];
}

- (void)launchAppInWindow:(UIWindow*)window {
    WMFStyleManager* manager = [WMFStyleManager new];
    [manager applyStyleToWindow:window];
    [WMFStyleManager setSharedStyleManager:manager];

    [window setRootViewController:self];
    [window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveWithNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)processShortcutItem:(UIApplicationShortcutItem*)item completion:(void (^)(BOOL))completion {
    self.shortcutItemSelectedAtLaunch = item;
    self.shortcutCompletion           = completion;
}

- (void)resumeApp {
    if (![self launchCompleted] || self.isPresentingOnboarding) {
        return;
    }

    if ([self shouldProcessAppShortcutOnLaunch]) {
        [self processApplicationShortcutItem];
    } else if ([self shouldShowExploreScreenOnLaunch]) {
        [self showExplore];
    } else if ([self shouldShowLastReadArticleOnLaunch]) {
        [self showLastReadArticleAnimated:YES];
    }

    if (FBTweakValue(@"Alerts", @"General", @"Show error on lanuch", NO)) {
        [[WMFAlertManager sharedInstance] showErrorAlert:[NSError errorWithDomain:@"WMFTestDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: @"There was an error"}] sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show warning on lanuch", NO)) {
        [[WMFAlertManager sharedInstance] showWarningAlert:@"You have been warned" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show success on lanuch", NO)) {
        [[WMFAlertManager sharedInstance] showSuccessAlert:@"You are successful" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show message on lanuch", NO)) {
        [[WMFAlertManager sharedInstance] showAlert:@"You have been notified" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
}

- (void)pauseApp {
    [self downloadAssetsFilesIfNecessary];
    [self performHousekeepingIfNecessary];
}

#pragma mark - Shortcut

- (void)processApplicationShortcutItem {
    UIApplicationShortcutItem* shortcutItemSelectedAtLaunch = self.shortcutItemSelectedAtLaunch;
    self.shortcutItemSelectedAtLaunch = nil;
    if (shortcutItemSelectedAtLaunch) {
        @weakify(self)
        void (^ handleSelection)() = ^void () {
            @strongify(self)
            if ([shortcutItemSelectedAtLaunch.type isEqualToString:WMFIconShortcutTypeSearch]) {
                [self.tabBarController setSelectedIndex:WMFAppTabTypeExplore];
                [self.exploreViewController wmf_showSearchAnimated:YES delegate:self.exploreViewController];
            } else if ([shortcutItemSelectedAtLaunch.type isEqualToString:WMFIconShortcutTypeRandom]) {
                [self.tabBarController setSelectedIndex:WMFAppTabTypeExplore];
                [self showRandomArticleAnimated:YES];
            } else if ([shortcutItemSelectedAtLaunch.type isEqualToString:WMFIconShortcutTypeNearby]) {
                [self.tabBarController setSelectedIndex:WMFAppTabTypeExplore];
                [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
                [self showNearbyListAnimated:YES];
            } else if ([shortcutItemSelectedAtLaunch.type isEqualToString:WMFIconShortcutTypeContinueReading]) {
                [self showLastReadArticleAnimated:YES];
            }
            if (self.shortcutCompletion) {
                self.shortcutCompletion(YES);
                self.shortcutCompletion = NULL;
            }
        };

        // Ensure the presentedViewController view controller (such as Search vc) has been hidden.
        UINavigationController* exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
        if (exploreNavController.presentedViewController) {
            [exploreNavController dismissViewControllerAnimated:NO completion:handleSelection];
        } else {
            handleSelection();
        }
    }
}

#pragma mark - Start App

- (void)startApp {
    [self showSplashView];
    @weakify(self)
    [self runDataMigrationIfNeededWithCompletion :^{
        @strongify(self)
        [self.imageMigration setupAndStart];
        [self.savedArticlesFetcher fetchAndObserveSavedPageList];
        [self presentOnboardingIfNeededWithCompletion:^(BOOL didShowOnboarding) {
            @strongify(self)
            [self loadMainUI];
            [self hideSplashViewAnimated:!didShowOnboarding];
            [self resumeApp];
            [[PiwikTracker sharedInstance] wmf_logView:[self rootViewControllerForTab:WMFAppTabTypeExplore]];
        }];
    }];
}

#pragma mark - Utilities

- (BOOL)launchCompleted {
    return launchToken != 0;
}

- (BOOL)shouldProcessAppShortcutOnLaunch {
    return self.shortcutItemSelectedAtLaunch != nil;
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

- (BOOL)shouldShowLastReadArticleOnLaunch {
    if (FBTweakValue(@"Last Open Article", @"General", @"Restore on Launch", YES)) {
        return YES;
    }

    NSDate* resignActiveDate = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) <= WMFTimeBeforeRefreshingExploreScreen) {
        if (![self exploreViewControllerIsDisplayingContent] && [self.tabBarController selectedIndex] == WMFAppTabTypeExplore) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)exploreViewControllerIsDisplayingContent {
    return [self navigationControllerForTab:WMFAppTabTypeExplore].viewControllers.count > 1;
}

- (UINavigationController*)navigationControllerForTab:(WMFAppTabType)tab {
    return (UINavigationController*)[self.rootTabBarController viewControllers][tab];
}

- (UIViewController<WMFAnalyticsLogging>*)rootViewControllerForTab:(WMFAppTabType)tab {
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchLanguageDidChangeWithNotification:) name:WMFSearchLanguageDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    dispatch_once(&launchToken, ^{
        [self startApp];
    });
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Onboarding

static NSString* const WMFDidShowOnboarding = @"DidShowOnboarding5.0";

- (BOOL)shouldShowOnboarding {
    if (FBTweakValue(@"Welcome", @"General", @"Show on launch (requires force quit)", NO)) {
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
    [self.tabBarController setSelectedIndex:WMFAppTabTypeExplore];
    [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
}

#pragma mark - Last Read Article

- (void)showLastReadArticleAnimated:(BOOL)animated {
    MWKTitle* lastRead = [[NSUserDefaults standardUserDefaults] wmf_openArticleTitle];
    if (lastRead) {
        if ([[self onscreenTitle] isEqualToTitle:lastRead]) {
            return;
        }
        [self.tabBarController setSelectedIndex:WMFAppTabTypeExplore];
        [self.exploreViewController wmf_pushArticleViewControllerWithTitle:lastRead discoveryMethod:MWKHistoryDiscoveryMethodReloadFromNetwork dataStore:self.session.dataStore animated:animated];
    }
}

- (MWKTitle*)onscreenTitle {
    UINavigationController* navVC = [self navigationControllerForTab:self.tabBarController.selectedIndex];
    if ([navVC.topViewController isKindOfClass:[WMFArticleContainerViewController class]]) {
        return ((WMFArticleContainerViewController*)navVC.topViewController).articleTitle;
    }
    return nil;
}

#pragma mark - App Shortcuts

- (void)showRandomArticleAnimated:(BOOL)animated {
    MWKSite* site = [self.session searchSite];
    [self.randomFetcher fetchRandomArticleWithSite:site].then(^(MWKSearchResult* result){
        MWKTitle* title = [site titleWithString:result.displayTitle];
        [self.exploreViewController wmf_pushArticleViewControllerWithTitle:title discoveryMethod:MWKHistoryDiscoveryMethodRandom dataStore:self.dataStore animated:animated];
    }).catch(^(NSError* error){
        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    });
}

- (void)showNearbyListAnimated:(BOOL)animated {
    MWKSite* site                           = [self.session searchSite];
    WMFLocationSearchListViewController* vc = [[WMFLocationSearchListViewController alloc] initWithSearchSite:site dataStore:self.dataStore];
    [[self navigationControllerForTab:WMFAppTabTypeExplore] pushViewController:vc animated:YES];
}

#pragma mark - House Keeping

- (void)performHousekeepingIfNecessary {
    NSDate* lastHousekeepingDate        = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastHousekeepingDate"];
    NSInteger daysSinceLastHouseKeeping = [[NSDate date] daysAfterDate:lastHousekeepingDate];
    //NSLog(@"daysSinceLastHouseKeeping = %ld", (long)daysSinceLastHouseKeeping);
    if (daysSinceLastHouseKeeping > 1) {
        //NSLog(@"Performing housekeeping...");
        MWKDataHousekeeping* dataHouseKeeping = [[MWKDataHousekeeping alloc] init];
        [dataHouseKeeping performHouseKeeping];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastHousekeepingDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Download Assets

- (void)downloadAssetsFilesIfNecessary {
    // Sync config/ios.json at most once per day.
    [[QueuesSingleton sharedInstance].assetsFetchManager.operationQueue cancelAllOperations];

    (void)[[AssetsFileFetcher alloc] initAndFetchAssetsFileOfType:WMFAssetsFileTypeConfig
                                                      withManager:[QueuesSingleton sharedInstance].assetsFetchManager
                                                           maxAge:kWMFMaxAgeDefault];
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

- (void)tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController {
    [self wmf_hideKeyboard];
    // TODO: remove if not used never more
//    WMFAppTabType tab = [[tabBarController viewControllers] indexOfObject:viewController];
//    [[PiwikTracker sharedInstance] wmf_logView:[self rootViewControllerForTab:tab]];
}

#pragma mark - Notifications

- (void)searchLanguageDidChangeWithNotification:(NSNotification*)note {
    [self configureExploreViewController];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController*)navigationController
      willShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated {
    BOOL isToolbarEmpty = [viewController toolbarItems].count == 0;
    [navigationController setToolbarHidden:isToolbarEmpty];
}

@end
