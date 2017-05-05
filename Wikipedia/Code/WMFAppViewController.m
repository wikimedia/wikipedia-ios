#import "WMFAppViewController.h"
#import "Wikipedia-Swift.h"

// Frameworks
#import <Masonry/Masonry.h>
#if WMF_TWEAKS_ENABLED
#import <Tweaks/FBTweakInline.h>
#endif
#import "PiwikTracker+WMFExtensions.h"

// Utility
#import "NSUserActivity+WMFExtensions.h"

#import "MWKDataStore.h"

// Networking
#import "SavedArticlesFetcher.h"
#import "SessionSingleton.h"
#import "AssetsFileFetcher.h"

// Model
#import "MWKSearchResult.h"
#import "MWKLanguageLinkController.h"

// Views
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIFont+WMFStyle.h"
#import "WMFStyleManager.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"
#import "UITabBarItem+WMFStyling.h"

// View Controllers
#import "WMFExploreViewController.h"
#import "WMFSearchViewController.h"
#import "WMFHistoryTableViewController.h"
#import "WMFSavedArticleTableViewController.h"
#import "WMFFirstRandomViewController.h"
#import "WMFRandomArticleViewController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFMorePageListViewController.h"
#import "UIViewController+WMFSearch.h"
#import "UINavigationController+WMFHideEmptyToolbar.h"

#import "AppDelegate.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"

#import "WMFDailyStatsLoggingFunnel.h"

#import "WMFNotificationsController.h"
#import "UIViewController+WMFOpenExternalUrl.h"

#import "WMFArticleNavigationController.h"

/**
 *  Enums for each tab in the main tab bar.
 *
 *  @warning Be sure to update `WMFAppTabCount` when these enums change, and always initialize the first enum to 0.
 *
 *  @see WMFAppTabCount
 */
typedef NS_ENUM(NSUInteger, WMFAppTabType) {
    WMFAppTabTypeExplore = 0,
    WMFAppTabTypePlaces,
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

static NSTimeInterval const WMFTimeBeforeShowingExploreScreenOnLaunch = 24 * 60 * 60;

static NSTimeInterval const WMFTimeBeforeRefreshingExploreFeed = 2 * 60 * 60;

@interface WMFAppViewController () <UITabBarControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, WMFLocationManagerDelegate>

@property (nonatomic, strong) IBOutlet UIView *splashView;
@property (nonatomic, strong) UITabBarController *rootTabBarController;

@property (nonatomic, strong, readonly) WMFExploreViewController *exploreViewController;
@property (nonatomic, strong, readonly) WMFSavedArticleTableViewController *savedArticlesViewController;
@property (nonatomic, strong, readonly) WMFHistoryTableViewController *recentArticlesViewController;

@property (nonatomic, strong) SavedArticlesFetcher *savedArticlesFetcher;
@property (nonatomic, strong, readonly) SessionSingleton *session;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

@property (nonatomic, strong) WMFDatabaseHouseKeeper *houseKeeper;

@property (nonatomic) BOOL isPresentingOnboarding;

@property (nonatomic, strong) NSUserActivity *unprocessedUserActivity;
@property (nonatomic, strong) UIApplicationShortcutItem *unprocessedShortcutItem;

@property (nonatomic) UIBackgroundTaskIdentifier housekeepingBackgroundTaskIdentifier;
@property (nonatomic) UIBackgroundTaskIdentifier migrationBackgroundTaskIdentifier;

@property (nonatomic, strong) WMFDailyStatsLoggingFunnel *statsFunnel;

@property (nonatomic, strong) WMFNotificationsController *notificationsController;

@property (nonatomic, getter=isWaitingToResumeApp) BOOL waitingToResumeApp;
@property (nonatomic, getter=isMigrationComplete) BOOL migrationComplete;
@property (nonatomic, getter=isMigrationActive) BOOL migrationActive;

@property (nonatomic, strong) WMFLocationManager *showNearbyLocationManager;

@property (nonatomic, strong) WMFTaskGroup *backgroundTaskGroup;

/// Use @c rootTabBarController instead.
- (UITabBarController *)tabBarController NS_UNAVAILABLE;

@end

@implementation WMFAppViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.housekeepingBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    self.migrationBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(isZeroRatedChanged:)
                                                 name:WMFZeroRatingChanged
                                               object:nil];

    @weakify(self);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      @strongify(self);
                                                      [self updateTabBarItemsTitleTextAttributesForNewDynamicTypeContentSize];
                                                  }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)updateTabBarItemsTitleTextAttributesForNewDynamicTypeContentSize {
    for (UITabBarItem *item in self.rootTabBarController.tabBar.items) {
        [item setTitleTextAttributes:[UITabBarItem wmf_rootTabBarItemStyleForState:UIControlStateNormal] forState:UIControlStateNormal];
        [item setTitleTextAttributes:[UITabBarItem wmf_rootTabBarItemStyleForState:UIControlStateSelected] forState:UIControlStateSelected];
    }
}

- (BOOL)isPresentingOnboarding {
    return [self.presentedViewController isKindOfClass:[WMFWelcomePageViewController class]];
}

- (BOOL)uiIsLoaded {
    return _rootTabBarController != nil;
}

- (NSURL *)siteURL {
    return [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
}

#pragma mark - Setup

- (void)loadMainUI {
    if ([self uiIsLoaded]) {
        return;
    }
    UITabBarController *tabBar = [[UIStoryboard storyboardWithName:@"WMFTabBarUI" bundle:nil] instantiateInitialViewController];
    [self addChildViewController:tabBar];
    [self.view insertSubview:tabBar.view atIndex:0];
    [tabBar.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.bottom.and.leading.and.trailing.equalTo(self.view);
    }];
    [tabBar didMoveToParentViewController:self];
    self.rootTabBarController = tabBar;
    [self configureTabController];
    [self configureExploreViewController];
    [self configurePlacesViewController];
    [self configureArticleListController:self.savedArticlesViewController];
    [self configureArticleListController:self.recentArticlesViewController];
    [[self class] wmf_setSearchButtonDataStore:self.dataStore];
}

- (void)configureTabController {
    self.rootTabBarController.delegate = self;
    for (WMFAppTabType i = 0; i < WMFAppTabCount; i++) {
        UINavigationController *navigationController = [self navigationControllerForTab:i];
        navigationController.delegate = self;
        navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)configureExploreViewController {
    [self.exploreViewController setUserStore:self.dataStore];
}

- (void)configurePlacesViewController {
    self.placesViewController.dataStore = self.dataStore;
}

- (void)configureArticleListController:(WMFArticleListTableViewController *)controller {
    controller.userDataStore = self.dataStore;
}

#pragma mark - Notifications

- (void)appWillEnterForegroundWithNotification:(NSNotification *)note {
    self.unprocessedUserActivity = nil;
    self.unprocessedShortcutItem = nil;

    // Retry migration if it was terminated by a background task ending
    [self migrateIfNecessary];
}

- (void)appDidBecomeActiveWithNotification:(NSNotification *)note {
    self.notificationsController.applicationActive = YES;

    if (![self uiIsLoaded]) {
        return;
    }

#if WMF_TWEAKS_ENABLED
    if (FBTweakValue(@"Notifications", @"In the news", @"Send on app open", NO)) {
        [self.dataStore.feedContentController debugSendRandomInTheNewsNotification];
    }
#endif
}

- (void)appWillResignActiveWithNotification:(NSNotification *)note {
    self.notificationsController.applicationActive = NO;

    if (![self uiIsLoaded]) {
        return;
    }

    NSError *saveError = nil;
    if (![self.dataStore save:&saveError]) {
        DDLogError(@"Error saving dataStore: %@", saveError);
    }
}

- (void)appDidEnterBackgroundWithNotification:(NSNotification *)note {
    if (![self uiIsLoaded]) {
        return;
    }
    [self startHousekeepingBackgroundTask];
    dispatch_async(dispatch_get_main_queue(), ^{
#if WMF_TWEAKS_ENABLED
        if (FBTweakValue(@"Notifications", @"In the news", @"Send on app exit", NO)) {
            [self.dataStore.feedContentController debugSendRandomInTheNewsNotification];
        }
#endif
        [self pauseApp];
    });
}

- (void)appLanguageDidChangeWithNotification:(NSNotification *)note {
    self.dataStore.feedContentController.siteURL = [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
    [self configureExploreViewController];
}

#pragma mark - Background Fetch

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isMigrationComplete) {
            completion(UIBackgroundFetchResultNoData);
            return;
        }
        [self.dataStore.feedContentController updateBackgroundSourcesWithCompletion:completion];
    });
}

#pragma mark - Background Tasks

- (void)startHousekeepingBackgroundTask {
    if (self.housekeepingBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        return;
    }
    self.housekeepingBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self.dataStore stopCacheRemoval];
        [self.savedArticlesFetcher cancelFetchForSavedPages];
        [self endHousekeepingBackgroundTask];
    }];
}

- (void)endHousekeepingBackgroundTask {
    if (self.housekeepingBackgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        return;
    }

    UIBackgroundTaskIdentifier backgroundTaskToStop = self.housekeepingBackgroundTaskIdentifier;
    self.housekeepingBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskToStop];
}

- (void)startMigrationBackgroundTask:(dispatch_block_t)expirationHandler {
    if (self.migrationBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        return;
    }
    self.migrationBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (expirationHandler) {
            expirationHandler();
        }
    }];
}

- (void)endMigrationBackgroundTask {
    if (self.migrationBackgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        return;
    }

    UIBackgroundTaskIdentifier backgroundTaskToStop = self.migrationBackgroundTaskIdentifier;
    self.migrationBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskToStop];
}

#pragma mark - Launch

+ (WMFAppViewController *)initialAppViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard storyboardWithName:NSStringFromClass([WMFAppViewController class]) bundle:nil] instantiateInitialViewController];
}

- (void)launchAppInWindow:(UIWindow *)window waitToResumeApp:(BOOL)waitToResumeApp {
    self.waitingToResumeApp = waitToResumeApp;
    WMFStyleManager *manager = [WMFStyleManager new];
    [manager applyStyleToWindow:window];
    [WMFStyleManager setSharedStyleManager:manager];

    [window setRootViewController:self];
    [window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundWithNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveWithNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundWithNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLanguageDidChangeWithNotification:) name:WMFAppLanguageDidChangeNotification object:nil];

    [self showSplashView];

    [self migrateIfNecessary];
}

- (void)migrateIfNecessary {
    if (self.isMigrationComplete || self.isMigrationActive) {
        return;
    }

    __block BOOL migrationsAllowed = YES;
    [self startMigrationBackgroundTask:^{
        migrationsAllowed = NO;
    }];
    dispatch_block_t bail = ^{
        [self endMigrationBackgroundTask];
        self.migrationActive = NO;
    };
    self.migrationActive = YES;
    [self migrateToSharedContainerIfNecessaryWithCompletion:^{
        if (!migrationsAllowed) {
            bail();
            return;
        }
        [self migrateToNewFeedIfNecessaryWithCompletion:^{
            if (!migrationsAllowed) {
                bail();
                return;
            }
            [self.dataStore performCoreDataMigrations:^{
                if (!migrationsAllowed) {
                    bail();
                    return;
                }
                [self migrateToQuadKeyLocationIfNecessaryWithCompletion:^{
                    if (!migrationsAllowed) {
                        bail();
                        return;
                    }
                    [self migrateToRemoveUnreferencedArticlesIfNecessaryWithCompletion:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self endMigrationBackgroundTask];
                            [self presentOnboardingIfNeededWithCompletion:^(BOOL didShowOnboarding) {
                                [self loadMainUI];
                                self.migrationComplete = YES;
                                self.migrationActive = NO;
                                if (!self.isWaitingToResumeApp) {
                                    [self resumeApp:^{
                                        [self hideSplashViewAnimated:!didShowOnboarding];
                                    }];
                                }
                            }];
                        });
                    }];
                }];
            }];
        }];
    }];
}

- (void)migrateToSharedContainerIfNecessaryWithCompletion:(nonnull dispatch_block_t)completion {
    if (![[NSUserDefaults wmf_userDefaults] wmf_didMigrateToSharedContainer]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError *error = nil;
            if (![MWKDataStore migrateToSharedContainer:&error]) {
                DDLogError(@"Error migrating data store: %@", error);
            }
            error = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateToSharedContainer:YES];
                completion();
            });
        });
    } else {
        completion();
    }
}

- (void)migrateToNewFeedIfNecessaryWithCompletion:(nonnull dispatch_block_t)completion {
    if ([[NSUserDefaults wmf_userDefaults] wmf_didMigrateToNewFeed]) {
        completion();
    } else {
        NSError *migrationError = nil;
        [self.dataStore migrateToCoreData:&migrationError];
        if (migrationError) {
            DDLogError(@"Error migrating: %@", migrationError);
        }
        [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateToNewFeed:YES];
        completion();
    }
}

- (void)migrateToQuadKeyLocationIfNecessaryWithCompletion:(nonnull dispatch_block_t)completion {
    [self.dataStore migrateToQuadKeyLocationIfNecessaryWithCompletion:^(NSError *_Nonnull error) {
        if (error) {
            DDLogError(@"Error during location migration: %@", error);
        }
        completion();
    }];
}

- (void)migrateToRemoveUnreferencedArticlesIfNecessaryWithCompletion:(nonnull dispatch_block_t)completion {
    if ([[NSUserDefaults wmf_userDefaults] wmf_didMigrateToFixArticleCache]) {
        completion();
    } else {
        [self.dataStore removeUnreferencedArticlesFromDiskCacheWithFailure:^(NSError *_Nonnull error) {
            DDLogError(@"Error during article migration: %@", error);
            completion();
        }
            success:^{
                [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateToFixArticleCache:YES];
                completion();
            }];
    }
}

#pragma mark - Start/Pause/Resume App

- (void)hideSplashScreenAndResumeApp {
    self.waitingToResumeApp = NO;
    if (self.isMigrationComplete) {
        [self resumeApp:^{
            [self hideSplashViewAnimated:true];
        }];
    }
}

- (void)resumeApp:(dispatch_block_t)completion {
    if (self.isPresentingOnboarding) {
        if (completion) {
            completion();
        }
        return;
    }

    if (![self uiIsLoaded]) {
        if (completion) {
            completion();
        }
        return;
    }

    dispatch_block_t done = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishResumingApp];
            if (completion) {
                completion();
            }
        });
    };

    if (self.unprocessedUserActivity) {
        [self processUserActivity:self.unprocessedUserActivity completion:done];
    } else if (self.unprocessedShortcutItem) {
        [self processShortcutItem:self.unprocessedShortcutItem
                       completion:^(BOOL didProcess) {
                           done();
                       }];
    } else if ([self shouldShowLastReadArticleOnLaunch]) {
        [self showLastReadArticleAnimated:NO];
        done();
    } else if ([self shouldShowExploreScreenOnLaunch]) {
        [self showExplore];
        done();
    } else {
        done();
    }
}

- (void)finishResumingApp {
    [self.statsFunnel logAppNumberOfDaysSinceInstall];

    [[WMFAuthenticationManager sharedInstance] loginWithSavedCredentialsWithSuccess:^(WMFAccountLoginResult *_Nonnull success) {
        DDLogDebug(@"\n\nSuccessfully logged in with saved credentials for user '%@'.\n\n", success.username);
    }
        userAlreadyLoggedInHandler:^(WMFCurrentlyLoggedInUser *_Nonnull currentLoggedInHandler) {
            DDLogDebug(@"\n\nUser '%@' is already logged in.\n\n", currentLoggedInHandler.name);
        }
        failure:^(NSError *_Nonnull error) {
            DDLogDebug(@"\n\nloginWithSavedCredentials failed with error '%@'.\n\n", error);
        }];

    [self.dataStore.feedContentController startContentSources];

    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    NSDate *feedRefreshDate = [defaults wmf_feedRefreshDate];
    NSDate *now = [NSDate date];

    BOOL locationAuthorized = [WMFLocationManager isAuthorized];

    if (!feedRefreshDate || [now timeIntervalSinceDate:feedRefreshDate] > WMFTimeBeforeRefreshingExploreFeed || [[NSCalendar wmf_gregorianCalendar] wmf_daysFromDate:feedRefreshDate toDate:now] > 0) {
        [self.exploreViewController updateFeedSourcesUserInititated:NO];
    } else if (locationAuthorized != [defaults wmf_locationAuthorized]) {
        [self.dataStore.feedContentController updateNearbyForce:NO completion:NULL];
    }

    [defaults wmf_setLocationAuthorized:locationAuthorized];

    [self.savedArticlesFetcher start];

#if WMF_TWEAKS_ENABLED
    if (FBTweakValue(@"Alerts", @"General", @"Show error on launch", NO)) {
        [[WMFAlertManager sharedInstance] showErrorAlert:[NSError errorWithDomain:@"WMFTestDomain" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"There was an error" }] sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
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
#endif
}

- (void)pauseApp {
    if (![self uiIsLoaded]) {
        return;
    }

    [self.savedArticlesFetcher stop];
    [self.dataStore.feedContentController stopContentSources];

    self.houseKeeper = [WMFDatabaseHouseKeeper new];
    //TODO: these tasks should be converted to async so we can end the background task as soon as possible
    [self.dataStore clearMemoryCache];
    [self downloadAssetsFilesIfNecessary];

    //TODO: implement completion block to cancel download task with the 2 tasks above
    NSError *housekeepingError = nil;
    NSArray<NSURL *> *deletedArticleURLs = [self.houseKeeper performHouseKeepingOnManagedObjectContext:self.dataStore.viewContext error:&housekeepingError];
    if (housekeepingError) {
        DDLogError(@"Error on cleanup: %@", housekeepingError);
    }

    if (deletedArticleURLs.count > 0) {
        [self.dataStore removeArticlesWithURLsFromCache:deletedArticleURLs];
    }

    if (self.backgroundTaskGroup) {
        return;
    }

    WMFTaskGroup *taskGroup = [WMFTaskGroup new];
    self.backgroundTaskGroup = taskGroup;

    [taskGroup enter];
    [self.dataStore startCacheRemoval:^{
        [taskGroup leave];
    }];

    [taskGroup enter];
    [self.savedArticlesFetcher fetchUncachedArticlesInSavedPages:^{
        [taskGroup leave];
    }];

    [taskGroup waitInBackgroundWithCompletion:^{
        WMFAssertMainThread(@"Completion assumed to be called on the main queue.");
        self.backgroundTaskGroup = nil;
        [self endHousekeepingBackgroundTask];
    }];
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    if (![self uiIsLoaded]) {
        return;
    }
    [super didReceiveMemoryWarning];
    [self.dataStore clearMemoryCache];
}

#pragma mark - Logging

- (WMFDailyStatsLoggingFunnel *)statsFunnel {
    if (!_statsFunnel) {
        _statsFunnel = [[WMFDailyStatsLoggingFunnel alloc] init];
    }
    return _statsFunnel;
}

#pragma mark - Shortcut

- (BOOL)canProcessShortcutItem:(UIApplicationShortcutItem *)item {
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

- (void)processShortcutItem:(UIApplicationShortcutItem *)item completion:(void (^)(BOOL))completion {
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
        [self showSearchAnimated:NO];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeRandom]) {
        [self showRandomArticleAnimated:NO];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeNearby]) {
        [self showNearbyListAnimated:NO];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeContinueReading]) {
        [self showLastReadArticleAnimated:NO];
    }
    if (completion) {
        completion(YES);
    }
}

#pragma mark - NSUserActivity

- (BOOL)canProcessUserActivity:(NSUserActivity *)activity {
    if (!activity) {
        return NO;
    }
    switch ([activity wmf_type]) {
        case WMFUserActivityTypeExplore:
        case WMFUserActivityTypePlaces:
        case WMFUserActivityTypeSavedPages:
        case WMFUserActivityTypeHistory:
        case WMFUserActivityTypeSearch:
        case WMFUserActivityTypeSettings:
        case WMFUserActivityTypeContent:
            return YES;
        case WMFUserActivityTypeSearchResults:
            if ([activity wmf_searchTerm] != nil) {
                return YES;
            } else {
                return NO;
            }
            break;
        case WMFUserActivityTypeArticle: {
            if (![activity wmf_articleURL]) {
                return NO;
            } else {
                return YES;
            }
        } break;
        case WMFUserActivityTypeGenericLink: {
            return YES;
        }
        default:
            return NO;
            break;
    }
}

- (BOOL)processUserActivity:(NSUserActivity *)activity completion:(dispatch_block_t)done {
    if (![self canProcessUserActivity:activity]) {
        done();
        return NO;
    }
    if (![self uiIsLoaded] || self.isWaitingToResumeApp) {
        self.unprocessedUserActivity = activity;
        done();
        return YES;
    }
    self.unprocessedUserActivity = nil;
    [self dismissViewControllerAnimated:NO completion:NULL];

    switch ([activity wmf_type]) {
        case WMFUserActivityTypeExplore:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            break;
        case WMFUserActivityTypePlaces: {
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypePlaces];
            [[self navigationControllerForTab:WMFAppTabTypePlaces] popToRootViewControllerAnimated:NO];
            NSURL *articleURL = activity.wmf_articleURL;
            if (articleURL) {
                [[self placesViewController] showArticleURL:articleURL];
            }
        } break;
        case WMFUserActivityTypeContent: {
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];

            UINavigationController *navController = [self navigationControllerForTab:WMFAppTabTypeExplore];
            [navController popToRootViewControllerAnimated:NO];
            NSURL *url = [activity wmf_contentURL];
            WMFContentGroup *group = [self.dataStore.viewContext contentGroupForURL:url];
            [self.exploreViewController presentMoreViewControllerForGroup:group animated:NO];

        } break;
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
            NSURL *URL = [activity wmf_articleURL];
            if (!URL) {
                done();
                return NO;
            }
            [self showArticleForURL:URL animated:NO completion:done];
            // don't call done block before this return, wait for completion ^
            return YES;
        } break;
        case WMFUserActivityTypeSettings:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            [self.exploreViewController showSettings];
            break;
        case WMFUserActivityTypeGenericLink:
            [self wmf_openExternalUrl:[activity wmf_articleURL]];
            break;
        default:
            done();
            return NO;
            break;
    }
    done();
    return YES;
}

#pragma mark - Utilities

- (void)selectExploreTabAndDismissPresentedViewControllers {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    if (self.exploreViewController.presentedViewController) {
        [self.exploreViewController dismissViewControllerAnimated:NO completion:NULL];
    }
}

- (WMFArticleViewController *)showArticleForURL:(NSURL *)articleURL animated:(BOOL)animated {
    return [self showArticleForURL:articleURL
                          animated:animated
                        completion:^{
                        }];
}

- (WMFArticleViewController *)showArticleForURL:(NSURL *)articleURL animated:(BOOL)animated completion:(nonnull dispatch_block_t)completion {
    if (!articleURL.wmf_title) {
        completion();
        return nil;
    }
    WMFArticleViewController *visibleArticleViewController = self.visibleArticleViewController;
    NSString *visibleKey = visibleArticleViewController.articleURL.wmf_articleDatabaseKey;
    NSString *articleKey = articleURL.wmf_articleDatabaseKey;
    if (visibleKey && articleKey && [visibleKey isEqualToString:articleKey]) {
        completion();
        return visibleArticleViewController;
    }
    [self selectExploreTabAndDismissPresentedViewControllers];
    return [self.exploreViewController wmf_pushArticleWithURL:articleURL dataStore:self.session.dataStore restoreScrollPosition:YES animated:animated articleLoadCompletion:completion];
}

- (BOOL)shouldShowExploreScreenOnLaunch {
    NSDate *resignActiveDate = [[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeShowingExploreScreenOnLaunch) {
        return YES;
    }
    return NO;
}

- (BOOL)exploreViewControllerIsDisplayingContent {
    return [self navigationControllerForTab:WMFAppTabTypeExplore].viewControllers.count > 1;
}

- (WMFArticleViewController *)visibleArticleViewController {
    UINavigationController *navVC = [self navigationControllerForTab:self.rootTabBarController.selectedIndex];
    UIViewController *topVC = navVC.topViewController;
    if ([topVC isKindOfClass:[WMFArticleViewController class]]) {
        return (WMFArticleViewController *)topVC;
    }
    return nil;
}

- (UINavigationController *)navigationControllerForTab:(WMFAppTabType)tab {
    return (UINavigationController *)[self.rootTabBarController viewControllers][tab];
}

- (UIViewController<WMFAnalyticsViewNameProviding> *)rootViewControllerForTab:(WMFAppTabType)tab {
    return [[[self navigationControllerForTab:tab] viewControllers] firstObject];
}

#pragma mark - Accessors

- (SavedArticlesFetcher *)savedArticlesFetcher {
    if (![self uiIsLoaded]) {
        return nil;
    }
    if (!_savedArticlesFetcher) {
        _savedArticlesFetcher =
            [[SavedArticlesFetcher alloc] initWithDataStore:[[SessionSingleton sharedInstance] dataStore]

                                              savedPageList:[self.dataStore savedPageList]];
    }
    return _savedArticlesFetcher;
}

- (WMFNotificationsController *)notificationsController {
    WMFNotificationsController *controller = [WMFNotificationsController sharedNotificationsController];
    controller.applicationActive = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    return controller;
}

- (SessionSingleton *)session {
    return [SessionSingleton sharedInstance];
}

- (MWKDataStore *)dataStore {
    return self.session.dataStore;
}

- (WMFExploreViewController *)exploreViewController {
    return (WMFExploreViewController *)[self rootViewControllerForTab:WMFAppTabTypeExplore];
}

- (WMFArticleListTableViewController *)savedArticlesViewController {
    return (WMFArticleListTableViewController *)[self rootViewControllerForTab:WMFAppTabTypeSaved];
}

- (WMFArticleListTableViewController *)recentArticlesViewController {
    return (WMFArticleListTableViewController *)[self rootViewControllerForTab:WMFAppTabTypeRecent];
}

- (PlacesViewController *)placesViewController {
    return (PlacesViewController *)[self rootViewControllerForTab:WMFAppTabTypePlaces];
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

static NSString *const WMFDidShowOnboarding = @"DidShowOnboarding5.3";

- (BOOL)shouldShowOnboarding {
#if WMF_TWEAKS_ENABLED
    if (FBTweakValue(@"Welcome", @"General", @"Show on launch (requires force quit)", NO) || [[NSProcessInfo processInfo] environment][@"WMFShowWelcomeView"].boolValue) {
        return YES;
    }
#endif
    NSNumber *didShow = [[NSUserDefaults wmf_userDefaults] objectForKey:WMFDidShowOnboarding];
    return !didShow.boolValue;
}

- (void)setDidShowOnboarding {
    [[NSUserDefaults wmf_userDefaults] setObject:@YES forKey:WMFDidShowOnboarding];
    [[NSUserDefaults wmf_userDefaults] synchronize];
}

- (void)presentOnboardingIfNeededWithCompletion:(void (^)(BOOL didShowOnboarding))completion {
    if ([self shouldShowOnboarding]) {
        WMFWelcomePageViewController *vc = [WMFWelcomePageViewController wmf_viewControllerFromWelcomeStoryboard];

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
    self.splashView.hidden = NO;
    self.splashView.alpha = 1.0;
}

- (void)hideSplashViewAnimated:(BOOL)animated {
    NSTimeInterval duration = animated ? 0.3 : 0.0;
    [UIView animateWithDuration:duration
        animations:^{
            self.splashView.alpha = 0.0;
        }
        completion:^(BOOL finished) {
            self.splashView.hidden = YES;
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
    NSURL *lastRead = [[NSUserDefaults wmf_userDefaults] wmf_openArticleURL];
    if (!lastRead) {
        return NO;
    }

#if WMF_TWEAKS_ENABLED
    if (FBTweakValue(@"Last Open Article", @"General", @"Restore on Launch", YES)) {
        return YES;
    }

    NSDate *resignActiveDate = [[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) < WMFTimeBeforeShowingExploreScreenOnLaunch) {
        if (![self exploreViewControllerIsDisplayingContent] && [self.rootTabBarController selectedIndex] == WMFAppTabTypeExplore) {
            return YES;
        }
    }

    return NO;
#else
    return YES;
#endif
}

- (void)showLastReadArticleAnimated:(BOOL)animated {
    NSURL *lastRead = [[NSUserDefaults wmf_userDefaults] wmf_openArticleURL];
    [self showArticleForURL:lastRead animated:animated];
}

#pragma mark - Show Search

- (void)showSearchAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }
    [self.exploreViewController wmf_showSearchAnimated:animated];
}

#pragma mark - App Shortcuts

- (void)showRandomArticleAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }

    WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:[self siteURL] dataStore:self.dataStore];
    [exploreNavController pushViewController:vc animated:animated];
}

- (void)showNearbyListAnimated:(BOOL)animated {
    if (![WMFLocationManager isAuthorized]) {
        self.showNearbyLocationManager = [WMFLocationManager coarseLocationManager];
        self.showNearbyLocationManager.delegate = self;
        [self.showNearbyLocationManager startMonitoringLocation];
        return;
    }
    [self _showNearbyListAnimated:animated];
}

- (void)_showNearbyListAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }
    [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
    [self.dataStore.feedContentController updateNearbyForce:YES
                                                 completion:^{
                                                     WMFAssertMainThread(@"Completion assumed to be called on the main thread");
                                                     WMFContentGroup *nearby = [self.dataStore.viewContext newestGroupOfKind:WMFContentGroupKindLocation];
                                                     if (!nearby) {
                                                         //TODO: show an error?
                                                         return;
                                                     }

                                                     NSArray *urls = nearby.content;

                                                     WMFMorePageListViewController *vc = [[WMFMorePageListViewController alloc] initWithGroup:nearby articleURLs:urls userDataStore:self.dataStore];
                                                     vc.cellType = WMFMorePageListCellTypeLocation;
                                                     [[self navigationControllerForTab:WMFAppTabTypeExplore] pushViewController:vc animated:animated];
                                                 }];
}

- (void)locationManager:(WMFLocationManager *)locationManager didChangeEnabledState:(BOOL)enabled {
    if (locationManager == self.showNearbyLocationManager && enabled) {
        [self _showNearbyListAnimated:YES];
        self.showNearbyLocationManager.delegate = nil;
        [self.showNearbyLocationManager stopMonitoringLocation];
    }
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

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self wmf_hideKeyboard];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (viewController == tabBarController.selectedViewController) {
        switch (tabBarController.selectedIndex) {
            case WMFAppTabTypeExplore: {
                WMFExploreViewController *exploreViewController = (WMFExploreViewController *)[self exploreViewController];
                [exploreViewController scrollToTop];
            } break;
            case WMFAppTabTypeSaved: {
                WMFArticleListTableViewController *savedArticlesViewController = (WMFArticleListTableViewController *)[self savedArticlesViewController];
                [savedArticlesViewController scrollToTop:savedArticlesViewController.userDataStore.savedPageList.numberOfItems > 0];
            } break;
            case WMFAppTabTypeRecent: {
                WMFArticleListTableViewController *historyArticlesViewController = (WMFArticleListTableViewController *)[self recentArticlesViewController];
                [historyArticlesViewController scrollToTop:[historyArticlesViewController.userDataStore.historyList numberOfItems] > 0];
            } break;
        }
    }

    if ([viewController isKindOfClass:[WMFArticleNavigationController class]]) {
        [(WMFArticleNavigationController *)viewController popToRootViewControllerAnimated:NO];
    }
    return YES;
}

- (void)updateActiveTitleAccessibilityButton:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[WMFExploreViewController class]]) {
        WMFExploreViewController *vc = (WMFExploreViewController *)viewController;
        vc.titleButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-title-accessibility-label", nil, nil, @"Wikipedia, scroll to top of Explore", @"Accessibility heading for the Explore page, indicating that tapping it will scroll to the top of the explore page. \"Explore\" is the same as {{msg-wikimedia|Wikipedia-ios-welcome-explore-title}}.");
    } else if ([viewController isKindOfClass:[WMFArticleViewController class]]) {
        WMFArticleViewController *vc = (WMFArticleViewController *)viewController;
        if (self.rootTabBarController.selectedIndex == WMFAppTabTypeExplore) {
            vc.titleButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-button-explore-accessibility-label", nil, nil, @"Wikipedia, return to Explore", @"Accessibility heading for articles shown within the explore tab, indicating that tapping it will take you back to explore. \"Explore\" is the same as {{msg-wikimedia|Wikipedia-ios-welcome-explore-title}}.");
        } else if (self.rootTabBarController.selectedIndex == WMFAppTabTypeSaved) {
            vc.titleButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-button-saved-accessibility-label", nil, nil, @"Wikipedia, return to Saved", @"Accessibility heading for articles shown within the saved articles tab, indicating that tapping it will take you back to the list of saved articles. \"Saved\" is the same as {{msg-wikimedia|Wikipedia-ios-saved-title}}.");
        } else if (self.rootTabBarController.selectedIndex == WMFAppTabTypeRecent) {
            vc.titleButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-button-history-accessibility-label", nil, nil, @"Wikipedia, return to History", @"Accessibility heading for articles shown within the history articles tab, indicating that tapping it will take you back to the history list. \"History\" is the same as {{msg-wikimedia|Wikipedia-ios-history-title}}.");
        }
    }
}
#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    navigationController.interactivePopGestureRecognizer.delegate = self;
    [navigationController wmf_hideToolbarIfViewControllerHasNoToolbarItems:viewController];
    [self updateActiveTitleAccessibilityButton:viewController];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([[navigationController viewControllers] count] == 1) {
        [[NSUserDefaults wmf_userDefaults] wmf_setOpenArticleURL:nil];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    for (WMFAppTabType i = 0; i < WMFAppTabCount; i++) {
        UINavigationController *navigationController = [self navigationControllerForTab:i];
        if (navigationController.interactivePopGestureRecognizer == gestureRecognizer) {
            return navigationController.viewControllers.count > 1;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ![gestureRecognizer isMemberOfClass:[UIScreenEdgePanGestureRecognizer class]];
}

#pragma mark - Wikipedia Zero

- (void)isZeroRatedChanged:(NSNotification *)note {
    WMFZeroConfigurationManager *zeroConfigurationManager = [note object];
    if (zeroConfigurationManager.isZeroRated) {
        [self showFirstTimeZeroOnAlertIfNeeded:zeroConfigurationManager.zeroConfiguration];
    } else {
        [self showZeroOffAlert];
    }
}

- (void)setZeroOnDialogShownOnce {
    [[NSUserDefaults wmf_userDefaults] setBool:YES forKey:WMFZeroOnDialogShownOnce];
    [[NSUserDefaults wmf_userDefaults] synchronize];
}

- (BOOL)zeroOnDialogShownOnce {
    return [[NSUserDefaults wmf_userDefaults] boolForKey:WMFZeroOnDialogShownOnce];
}

- (void)showFirstTimeZeroOnAlertIfNeeded:(WMFZeroConfiguration *)zeroConfiguration {
    if ([self zeroOnDialogShownOnce]) {
        return;
    }

    [self setZeroOnDialogShownOnce];

    NSString *title = zeroConfiguration.message ? zeroConfiguration.message : WMFLocalizedStringWithDefaultValue(@"zero-free-verbiage", nil, nil, @"Free Wikipedia access from your mobile operator (data charges waived)", @"Alert text for Wikipedia Zero free data access enabled");

    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:title message:WMFLocalizedStringWithDefaultValue(@"zero-learn-more", nil, nil, @"Data charges are waived for this Wikipedia app.", @"Alert text for learning more about Wikipedia Zero") preferredStyle:UIAlertControllerStyleAlert];

    [dialog addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"zero-learn-more-no-thanks", nil, nil, @"Dismiss", @"Button text for declining to learn more about Wikipedia Zero.\n{{Identical|Dismiss}}") style:UIAlertActionStyleCancel handler:NULL]];

    [dialog addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"zero-learn-more-learn-more", nil, nil, @"Read more", @"Button text for learn more about Wikipedia Zero.\n{{Identical|Read more}}")
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *_Nonnull action) {
                                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://m.wikimediafoundation.org/wiki/Wikipedia_Zero_App_FAQ"]];
                                             }]];

    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:dialog animated:YES completion:NULL];
}

- (void)showZeroOffAlert {

    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:WMFLocalizedStringWithDefaultValue(@"zero-charged-verbiage", nil, nil, @"Wikipedia Zero is off", @"Alert text for Wikipedia Zero free data access disabled") message:WMFLocalizedStringWithDefaultValue(@"zero-charged-verbiage-extended", nil, nil, @"Loading other articles may incur data charges. Saved articles stored offline do not use data and are free.", @"Extended text describing that further usage of the app may in fact incur data charges because Wikipedia Zero is off, but Saved articles are still free.") preferredStyle:UIAlertControllerStyleAlert];

    [dialog addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"zero-learn-more-no-thanks", nil, nil, @"Dismiss", @"Button text for declining to learn more about Wikipedia Zero.\n{{Identical|Dismiss}}") style:UIAlertActionStyleCancel handler:NULL]];

    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:dialog animated:YES completion:NULL];
}

#pragma mark - UNUserNotificationCenterDelegate

// The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert);
}

// The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    NSString *categoryIdentifier = response.notification.request.content.categoryIdentifier;
    NSString *actionIdentifier = response.actionIdentifier;
    if ([categoryIdentifier isEqualToString:WMFInTheNewsNotificationCategoryIdentifier]) {
        NSDictionary *info = response.notification.request.content.userInfo;
        NSString *articleURLString = info[WMFNotificationInfoArticleURLStringKey];
        NSURL *articleURL = [NSURL URLWithString:articleURLString];
        if ([actionIdentifier isEqualToString:WMFInTheNewsNotificationShareActionIdentifier]) {
            WMFArticleViewController *articleVC = [self showArticleForURL:articleURL animated:NO];
            [articleVC shareArticleWhenReady];
        } else if ([actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
            [[PiwikTracker sharedInstance] wmf_logActionTapThroughInContext:@"notification" contentType:articleURL.host];
            [self showInTheNewsForNotificationInfo:info];
        } else if ([actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
        }
    }

    completionHandler();
}

- (void)showInTheNewsForNotificationInfo:(NSDictionary *)info {
    NSString *articleURLString = info[WMFNotificationInfoArticleURLStringKey];
    NSURL *articleURL = [NSURL URLWithString:articleURLString];
    NSDictionary *JSONDictionary = info[WMFNotificationInfoFeedNewsStoryKey];
    NSError *JSONError = nil;
    WMFFeedNewsStory *feedNewsStory = [MTLJSONAdapter modelOfClass:[WMFFeedNewsStory class] fromJSONDictionary:JSONDictionary error:&JSONError];
    if (!feedNewsStory || JSONError) {
        DDLogError(@"Error parsing feed news story: %@", JSONError);
        [self showArticleForURL:articleURL animated:NO];
        return;
    }
    [self selectExploreTabAndDismissPresentedViewControllers];
    [self.exploreViewController showInTheNewsForStory:feedNewsStory date:nil animated:NO];
}

#pragma mark - Perma Random Mode

#if WMF_TWEAKS_ENABLED
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if ([super respondsToSelector:@selector(motionEnded:withEvent:)]) {
        [super motionEnded:motion withEvent:event];
    }
    if (event.subtype != UIEventSubtypeMotionShake) {
        return;
    }
    UINavigationController *navController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if ([navController.visibleViewController isKindOfClass:[WMFRandomArticleViewController class]] || [navController.visibleViewController isKindOfClass:[WMFFirstRandomViewController class]]) {
        return;
    }
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }

    WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:[self siteURL] dataStore:self.dataStore];
    vc.permaRandomMode = YES;
    [exploreNavController pushViewController:vc animated:YES];
}
#endif

@end
