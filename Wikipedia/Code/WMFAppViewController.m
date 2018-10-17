#import "WMFAppViewController.h"
@import WMF;
#import "Wikipedia-Swift.h"

#define DEBUG_THEMES 1

#if WMF_TWEAKS_ENABLED
#import <Tweaks/FBTweakInline.h>
#endif

// Networking
#import "SavedArticlesFetcher.h"

// Views
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"

// View Controllers
#import "WMFSettingsViewController.h"
#import "WMFFirstRandomViewController.h"
#import "WMFRandomArticleViewController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "UINavigationController+WMFHideEmptyToolbar.h"

#import "AppDelegate.h"

#import "WMFDailyStatsLoggingFunnel.h"

#import "UIViewController+WMFOpenExternalUrl.h"

#import "WMFArticleNavigationController.h"
#import "WMFSearchButton.h"
#import "Wikipedia-Swift.h"
#import "EXTScope.h"

/**
 *  Enums for each tab in the main tab bar.
 *
 *  @warning Be sure to update `WMFAppTabCount` when these enums change, and always initialize the first enum to 0.
 *
 *  @see WMFAppTabCount
 */
typedef NS_ENUM(NSUInteger, WMFAppTabType) {
    WMFAppTabTypeMain = 0,
    WMFAppTabTypePlaces,
    WMFAppTabTypeSaved,
    WMFAppTabTypeRecent,
    WMFAppTabTypeSearch
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
static NSUInteger const WMFAppTabCount = WMFAppTabTypeSearch + 1;

static NSTimeInterval const WMFTimeBeforeShowingExploreScreenOnLaunch = 24 * 60 * 60;

static CFTimeInterval const WMFRemoteAppConfigCheckInterval = 3 * 60 * 60;
static NSString *const WMFLastRemoteAppConfigCheckAbsoluteTimeKey = @"WMFLastRemoteAppConfigCheckAbsoluteTimeKey";

static const NSString *kvo_NSUserDefaults_defaultTabType = @"kvo_NSUserDefaults_defaultTabType";
static const NSString *kvo_SavedArticlesFetcher_progress = @"kvo_SavedArticlesFetcher_progress";

@interface WMFAppViewController () <UITabBarControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, WMFThemeable, ReadMoreAboutRevertedEditViewControllerDelegate>

@property (nonatomic, strong) WMFPeriodicWorkerController *periodicWorkerController;
@property (nonatomic, strong) WMFBackgroundFetcherController *backgroundFetcherController;
@property (nonatomic, strong) WMFReachabilityNotifier *reachabilityNotifier;

@property (nonatomic, strong) UIImageView *splashView;
@property (nonatomic, strong) WMFViewControllerTransitionsController *transitionsController;

@property (nonatomic, strong) WMFSettingsViewController *settingsViewController;
@property (nonatomic, strong, readonly) ExploreViewController *exploreViewController;
@property (nonatomic, strong, readonly) SearchViewController *searchViewController;
@property (nonatomic, strong, readonly) WMFSavedViewController *savedViewController;
@property (nonatomic, strong, readonly) WMFPlacesViewController *placesViewController;
@property (nonatomic, strong, readonly) WMFHistoryViewController *recentArticlesViewController;

@property (nonatomic, strong) SavedArticlesFetcher *savedArticlesFetcher;
@property (nonatomic, strong, readonly) SessionSingleton *session;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

@property (nonatomic, strong) WMFDatabaseHouseKeeper *houseKeeper;

@property (nonatomic) BOOL isPresentingOnboarding;

@property (nonatomic, strong) NSUserActivity *unprocessedUserActivity;
@property (nonatomic, strong) UIApplicationShortcutItem *unprocessedShortcutItem;

@property (nonatomic) UIBackgroundTaskIdentifier housekeepingBackgroundTaskIdentifier;
@property (nonatomic) UIBackgroundTaskIdentifier migrationBackgroundTaskIdentifier;
@property (nonatomic) UIBackgroundTaskIdentifier feedContentFetchBackgroundTaskIdentifier;

@property (nonatomic, strong) WMFNotificationsController *notificationsController;

@property (nonatomic, getter=isWaitingToResumeApp) BOOL waitingToResumeApp;
@property (nonatomic, getter=isMigrationComplete) BOOL migrationComplete;
@property (nonatomic, getter=isMigrationActive) BOOL migrationActive;
@property (nonatomic, getter=isResumeComplete) BOOL resumeComplete; //app has fully loaded & login was attempted

@property (nonatomic, getter=isCheckingRemoteConfig) BOOL checkingRemoteConfig;

@property (nonatomic, copy) NSDictionary *notificationUserInfoToShow;

@property (nonatomic, strong) WMFTaskGroup *backgroundTaskGroup;

@property (nonatomic, strong) WMFTheme *theme;

@property (nonatomic, strong) UINavigationController *settingsNavigationController;

@property (nonatomic, strong, readwrite) WMFReadingListsAlertController *readingListsAlertController;

@property (nonatomic, strong, readwrite) NSDate *syncStartDate;

@property (nonatomic, strong) SavedTabBarItemProgressBadgeManager *savedTabBarItemProgressBadgeManager;

@property (nonatomic) BOOL hasSyncErrorBeenShownThisSesssion;

@property (nonatomic, strong) RemoteNotificationsModelChangeResponseCoordinator *remoteNotificationsModelChangeResponseCoordinator;

@end

@implementation WMFAppViewController
@synthesize exploreViewController = _exploreViewController;
@synthesize searchViewController = _searchViewController;
@synthesize savedViewController = _savedViewController;
@synthesize recentArticlesViewController = _recentArticlesViewController;
@synthesize placesViewController = _placesViewController;
@synthesize splashView = _splashView;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults wmf] removeObserver:self forKeyPath:[WMFUserDefaultsKey defaultTabType]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.theme = [[NSUserDefaults wmf] wmf_appTheme];

    self.housekeepingBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    self.migrationBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(isZeroRatedChanged:)
                                                 name:WMFZeroRatingChanged
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navigateToActivityNotification:)
                                                 name:WMFNavigateToActivityNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeTheme:)
                                                 name:WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(articleFontSizeWasUpdated:)
                                                 name:WMFFontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(entriesLimitReachedWithNotification:)
                                                 name:[ReadingList entriesLimitReachedNotification]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readingListsWereSplitNotification:)
                                                 name:[WMFReadingListsController readingListsWereSplitNotification]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readingListsServerDidConfirmSyncWasEnabledForAccountWithNotification:)
                                                 name:[WMFReadingListsController readingListsServerDidConfirmSyncWasEnabledForAccountNotification]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncDidStartNotification:)
                                                 name:[WMFReadingListsController syncDidStartNotification]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncDidFinishNotification:)
                                                 name:[WMFReadingListsController syncDidFinishNotification]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(conflictingReadingListNameUpdatedNotification:)
                                                 name:[ReadingList conflictingReadingListNameUpdatedNotification]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(articleSaveToDiskDidFail:)
                                                 name:WMFArticleSaveToDiskDidFailNotification
                                               object:nil];

    [[NSUserDefaults wmf] addObserver:self
                           forKeyPath:[WMFUserDefaultsKey defaultTabType]
                              options:NSKeyValueObservingOptionNew
                              context:&kvo_NSUserDefaults_defaultTabType];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exploreFeedPreferencesDidChange:)
                                                 name:WMFExploreFeedPreferencesDidChangeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(remoteNotificationsModelDidChange:)
                                                 name:[RemoteNotificationsModelControllerNotification modelDidChange]
                                               object:nil];

    self.readingListsAlertController = [[WMFReadingListsAlertController alloc] init];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.theme.preferredStatusBarStyle;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)isPresentingOnboarding {
    return [self.presentedViewController isKindOfClass:[WMFWelcomeInitialViewController class]];
}

- (BOOL)uiIsLoaded {
    return self.viewControllers.count > 0;
}

- (NSURL *)siteURL {
    return [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
}

#pragma mark - Setup

- (void)loadMainUI {
    if ([self uiIsLoaded]) {
        return;
    }

    self.tabBar.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;

    WMFArticleNavigationController *exploreNavC = [[WMFArticleNavigationController alloc] initWithRootViewController:[self exploreViewController]];
    exploreNavC.tabBarItem.image = [UIImage imageNamed:@"tabbar-explore"];
    WMFArticleNavigationController *placesNavC = [[WMFArticleNavigationController alloc] initWithRootViewController:[self placesViewController]];
    placesNavC.tabBarItem.image = [UIImage imageNamed:@"tabbar-nearby"];
    WMFArticleNavigationController *savedNavC = [[WMFArticleNavigationController alloc] initWithRootViewController:[self savedViewController]];
    savedNavC.tabBarItem.image = [UIImage imageNamed:@"tabbar-save"];
    WMFArticleNavigationController *historyNavC = [[WMFArticleNavigationController alloc] initWithRootViewController:[self recentArticlesViewController]];
    historyNavC.tabBarItem.image = [UIImage imageNamed:@"tabbar-recent"];
    WMFArticleNavigationController *searchNavC = [[WMFArticleNavigationController alloc] initWithRootViewController:[self searchViewController]];
    searchNavC.tabBarItem.image = [UIImage imageNamed:@"search"];

    NSArray<WMFArticleNavigationController *> *navigationControllers = @[exploreNavC, placesNavC, savedNavC, historyNavC, searchNavC];
    for (WMFArticleNavigationController *navC in navigationControllers) {
        navC.extendedLayoutIncludesOpaqueBars = YES;
        [navC setNavigationBarHidden:YES animated:NO];
    }
    [self setViewControllers:navigationControllers animated:NO];

    [self applyTheme:self.theme];

    self.transitionsController = [WMFViewControllerTransitionsController new];
    [self configureTabController];

    self.recentArticlesViewController.dataStore = self.dataStore;
    [self.searchViewController applyTheme:self.theme];
    [self.settingsViewController applyTheme:self.theme];

    UITabBarItem *savedTabBarItem = [[self navigationControllerForTab:WMFAppTabTypeSaved] tabBarItem];
    self.savedTabBarItemProgressBadgeManager = [[SavedTabBarItemProgressBadgeManager alloc] initWithTabBarItem:savedTabBarItem];

    BOOL shouldOpenAppOnSearchTab = [NSUserDefaults wmf].wmf_openAppOnSearchTab;
    if (shouldOpenAppOnSearchTab && self.selectedIndex != WMFAppTabTypeSearch) {
        [self setSelectedIndex:WMFAppTabTypeSearch];
    } else if (self.selectedIndex != WMFAppTabTypeMain) {
        [self setSelectedIndex:WMFAppTabTypeMain];
    }
}

- (void)configureTabController {
    self.delegate = self;
    for (WMFAppTabType i = 0; i < WMFAppTabCount; i++) {
        UINavigationController *navigationController = [self navigationControllerForTab:i];
        navigationController.delegate = self;
        navigationController.interactivePopGestureRecognizer.delegate = self;
        switch (i) {
            case WMFAppTabTypeSaved:
                navigationController.title = [WMFCommonStrings savedTabTitle];
                break;
            case WMFAppTabTypePlaces:
                navigationController.title = [WMFCommonStrings placesTabTitle];
                break;
            case WMFAppTabTypeRecent:
                navigationController.title = [WMFCommonStrings historyTabTitle];
                break;
            case WMFAppTabTypeSearch:
                navigationController.title = [WMFCommonStrings searchTitle];
                break;
            case WMFAppTabTypeMain:
                [self configureDefaultNavigationController:navigationController animated:NO];
                break;
            default:
                break;
        }
    }
}

- (void)configureDefaultNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    switch ([NSUserDefaults wmf].defaultTabType) {
        case WMFAppDefaultTabTypeExplore:
            navigationController.title = [WMFCommonStrings exploreTabTitle];
            [navigationController setNavigationBarHidden:YES animated:animated];
            navigationController.viewControllers = @[self.exploreViewController];
            [self configureExploreViewController];
            break;
        case WMFAppDefaultTabTypeSettings:
            navigationController.viewControllers = @[self.settingsViewController];
            navigationController.title = [WMFCommonStrings settingsTitle];
            self.settingsViewController.navigationItem.title = [WMFCommonStrings settingsTitle];
    }
}

- (void)configureExploreViewController {
    [self.exploreViewController applyTheme:self.theme];
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    settingsBarButtonItem.accessibilityLabel = [WMFCommonStrings settingsTitle];
    self.exploreViewController.navigationItem.rightBarButtonItem = settingsBarButtonItem;
}

#pragma mark - Notifications

- (void)appWillEnterForegroundWithNotification:(NSNotification *)note {
    self.unprocessedUserActivity = nil;
    self.unprocessedShortcutItem = nil;

    [[SessionsFunnel shared] logSessionStart];
    [UserHistoryFunnel.shared logSnapshot];

    // Retry migration if it was terminated by a background task ending
    [self migrateIfNecessary];

    if (self.isResumeComplete) {
        [self checkRemoteAppConfigIfNecessary];
        [self.periodicWorkerController start];
        [self.savedArticlesFetcher start];
    }
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

- (void)preferredLanguagesDidChange:(NSNotification *)note {
    [self updateExploreFeedPreferencesIfNecessary];
    self.dataStore.feedContentController.siteURLs = [[MWKLanguageLinkController sharedInstance] preferredSiteURLs];
    [self configureExploreViewController];
}

/**
 Updates explore feed preferences if new preferred language was appeneded or removed.
 */
- (void)updateExploreFeedPreferencesIfNecessary {
    MWKLanguageLinkController *languageLinkController = [MWKLanguageLinkController sharedInstance];
    NSArray<MWKLanguageLink *> *preferredLanguages = languageLinkController.preferredLanguages;
    NSArray<MWKLanguageLink *> *previousPreferredLanguages = languageLinkController.previousPreferredLanguages;
    if (preferredLanguages.count == previousPreferredLanguages.count) { // reordered
        return;
    }
    MWKLanguageLink *mostRecentlyModifiedPreferredLanguage = languageLinkController.mostRecentlyModifiedPreferredLanguage;
    NSURL *siteURL = mostRecentlyModifiedPreferredLanguage.siteURL;
    BOOL appendedNewPreferredLanguage = [preferredLanguages containsObject:mostRecentlyModifiedPreferredLanguage];
    if (self.isPresentingOnboarding) {
        return;
    }
    [self.dataStore.feedContentController toggleContentForSiteURL:siteURL isOn:appendedNewPreferredLanguage waitForCallbackFromCoordinator:NO updateFeed:NO];
}

- (void)readingListsWereSplitNotification:(NSNotification *)note {
    NSInteger entryLimit = [note.userInfo[WMFReadingListsController.readingListsWereSplitNotificationEntryLimitKey] integerValue];
    [[WMFAlertManager sharedInstance] showWarningAlert:[NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"reading-lists-split-notification", nil, nil, @"There is a limit of %1$d articles per reading list. Existing lists with more than this limit have been split into multiple lists.", @"Alert message informing user that existing lists exceeding the entry limit have been split into multiple lists. %1$d will be replaced with the maximum number of articles allowed per reading list."), entryLimit] sticky:YES dismissPreviousAlerts:YES tapCallBack:nil];
}

- (void)readingListsServerDidConfirmSyncWasEnabledForAccountWithNotification:(NSNotification *)note {
    BOOL wasSyncEnabledForAccount = [note.userInfo[WMFReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncEnabledKey] boolValue];
    BOOL wasSyncEnabledOnDevice = [note.userInfo[WMFReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncEnabledOnDeviceKey] boolValue];
    BOOL wasSyncDisabledOnDevice = [note.userInfo[WMFReadingListsController.readingListsServerDidConfirmSyncWasEnabledForAccountWasSyncDisabledOnDeviceKey] boolValue];
    if (wasSyncEnabledForAccount) {
        [self wmf_showSyncEnabledPanelOncePerLoginWithTheme:self.theme wasSyncEnabledOnDevice:wasSyncEnabledOnDevice];
    } else if (!wasSyncDisabledOnDevice) {
        [self wmf_showEnableReadingListSyncPanelWithTheme:self.theme
                                             oncePerLogin:true
                             didNotPresentPanelCompletion:^{
                                 [self wmf_showSyncDisabledPanelWithTheme:self.theme wasSyncEnabledOnDevice:wasSyncEnabledOnDevice];
                             }
                                           dismissHandler:nil];
    }
}

- (void)syncDidStartNotification:(NSNotification *)note {
    self.syncStartDate = [NSDate date];
}

- (void)syncDidFinishNotification:(NSNotification *)note {
    NSError *error = (NSError *)note.userInfo[WMFReadingListsController.syncDidFinishErrorKey];

    // Reminder: kind of class is checked here because `syncDidFinishErrorKey` is sometimes set to a `WMF.ReadingListError` error type which doesn't bridge to Obj-C (causing the call to `wmf_isNetworkConnectionError` to crash).
    if ([error isKindOfClass:[NSError class]] && error.wmf_isNetworkConnectionError) {
        if (!self.hasSyncErrorBeenShownThisSesssion) {
            self.hasSyncErrorBeenShownThisSesssion = YES; //only show sync error once for multiple failed syncs
            [[WMFAlertManager sharedInstance] showWarningAlert:WMFLocalizedStringWithDefaultValue(@"reading-lists-sync-error-no-internet-connection", nil, nil, @"Syncing will resume when internet connection is available", @"Alert message informing user that syncing will resume when internet connection is available.")
                                                        sticky:YES
                                         dismissPreviousAlerts:YES
                                                   tapCallBack:nil];
        }
    }

    if (!error) {
        self.hasSyncErrorBeenShownThisSesssion = NO; // reset on successful sync
        if ([[NSDate date] timeIntervalSinceDate:self.syncStartDate] >= 5) {
            NSInteger syncedReadingListsCount = [note.userInfo[WMFReadingListsController.syncDidFinishSyncedReadingListsCountKey] integerValue];
            NSInteger syncedReadingListEntriesCount = [note.userInfo[WMFReadingListsController.syncDidFinishSyncedReadingListEntriesCountKey] integerValue];
            if (syncedReadingListsCount > 1 && syncedReadingListEntriesCount > 1) { // // TODO: When localization script supports multiple plurals per string, update to > 0
                // TODO: When localization script supports multiple plurals per string, update to use plurals.
                NSString *alertTitle = [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"reading-lists-large-sync-completed", nil, nil, @"%1$d articles and %2$d reading lists synced from your account", @"Alert message informing user that large sync was completed. %1$d will be replaced with the number of articles which were synced and %2$d will be replaced with the number of reading lists which were synced"), syncedReadingListEntriesCount, syncedReadingListsCount];
                [[WMFAlertManager sharedInstance] showSuccessAlert:alertTitle
                                                            sticky:YES
                                             dismissPreviousAlerts:YES
                                                       tapCallBack:nil];
            }
        }
    }
}

- (void)conflictingReadingListNameUpdatedNotification:(NSNotification *)note {
    NSString *oldName = (NSString *)note.userInfo[ReadingList.conflictingReadingListNameUpdatedOldNameKey];
    NSString *newName = (NSString *)note.userInfo[ReadingList.conflictingReadingListNameUpdatedNewNameKey];
    NSString *alertTitle = [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"reading-lists-conflicting-reading-list-name-updated", nil, nil, @"Your list '%1$@' has been renamed to '%2$@'", @"Alert message informing user that their reading list was renamed. %1$@ will be replaced the previous name of the list. %2$@ will be replaced with the new name of the list."), oldName, newName];
    [[WMFAlertManager sharedInstance] showWarningAlert:alertTitle
                                                sticky:YES
                                 dismissPreviousAlerts:YES
                                           tapCallBack:nil];
}

- (void)exploreFeedPreferencesDidChange:(NSNotification *)note {
    ExploreFeedPreferencesUpdateCoordinator *exploreFeedPreferencesUpdateCoordinator = (ExploreFeedPreferencesUpdateCoordinator *)note.object;
    [exploreFeedPreferencesUpdateCoordinator coordinateUpdateFrom:self];
}

#pragma mark - Explore feed preferences

- (void)updateDefaultTab {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.settingsNavigationController popToRootViewControllerAnimated:NO];
        dispatch_block_t update = ^{
            [self setSelectedIndex:WMFAppTabTypeSearch];
            [[self navigationControllerForTab:WMFAppTabTypeSearch] popToRootViewControllerAnimated:NO];
            [self configureDefaultNavigationController:[self navigationControllerForTab:WMFAppTabTypeMain] animated:NO];
        };
        if (self.presentedViewController) {
            [self.presentedViewController dismissViewControllerAnimated:YES completion:update];
        } else {
            update();
        }
    });
}

#pragma mark - Background Fetch

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isMigrationComplete) {
            completion(UIBackgroundFetchResultNoData);
            return;
        }

        [self.backgroundFetcherController performBackgroundFetch:completion];
    });
}

#pragma mark - Background Tasks

- (void)startHousekeepingBackgroundTask {
    if (self.housekeepingBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        return;
    }
    self.housekeepingBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self.dataStore stopCacheRemoval];
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

- (void)feedContentControllerBusyStateDidChange:(NSNotification *)note {
    if ([note object] != self.dataStore.feedContentController) {
        return;
    }

    UIBackgroundTaskIdentifier currentTaskIdentifier = self.feedContentFetchBackgroundTaskIdentifier;
    if (self.dataStore.feedContentController.isBusy && currentTaskIdentifier == UIBackgroundTaskInvalid) {
        self.feedContentFetchBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"com.wikipedia.background.task.feed.content"
                                                                                                     expirationHandler:^{
                                                                                                         [self.dataStore.feedContentController cancelAllFetches];
                                                                                                     }];
    } else if (!self.dataStore.feedContentController.isBusy && currentTaskIdentifier != UIBackgroundTaskInvalid) {
        self.feedContentFetchBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
        [[UIApplication sharedApplication] endBackgroundTask:currentTaskIdentifier];
    }
}
#pragma mark - Launch

- (void)launchAppInWindow:(UIWindow *)window waitToResumeApp:(BOOL)waitToResumeApp {
    self.waitingToResumeApp = waitToResumeApp;

    [window setRootViewController:self];
    [window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundWithNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveWithNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundWithNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedContentControllerBusyStateDidChange:) name:WMFExploreFeedContentControllerBusyStateDidChange object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredLanguagesDidChange:) name:WMFPreferredLanguagesDidChangeNotification object:nil];

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
                        if (!migrationsAllowed) {
                            bail();
                            return;
                        }
                        [self.dataStore performLibraryUpdates:^{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self endMigrationBackgroundTask];
                                [self checkRemoteAppConfigIfNecessary];
                                [self presentOnboardingIfNeededWithCompletion:^(BOOL didShowOnboarding) {
                                    [self loadMainUI];
                                    self.migrationComplete = YES;
                                    self.migrationActive = NO;
                                    [[SessionsFunnel shared] logSessionStart];
                                    [[UserHistoryFunnel shared] logStartingSnapshot];
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
    }];
}

- (void)migrateToSharedContainerIfNecessaryWithCompletion:(nonnull dispatch_block_t)completion {
    if (![[NSUserDefaults wmf] wmf_didMigrateToSharedContainer]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError *error = nil;
            if (![MWKDataStore migrateToSharedContainer:&error]) {
                DDLogError(@"Error migrating data store: %@", error);
            }
            error = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults wmf] wmf_setDidMigrateToSharedContainer:YES];
                completion();
            });
        });
    } else {
        completion();
    }
}

- (void)migrateToNewFeedIfNecessaryWithCompletion:(nonnull dispatch_block_t)completion {
    if ([[NSUserDefaults wmf] wmf_didMigrateToNewFeed]) {
        completion();
    } else {
        NSError *migrationError = nil;
        [self.dataStore migrateToCoreData:&migrationError];
        if (migrationError) {
            DDLogError(@"Error migrating: %@", migrationError);
        }
        [[NSUserDefaults wmf] wmf_setDidMigrateToNewFeed:YES];
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
    if ([[NSUserDefaults wmf] wmf_didMigrateToFixArticleCache]) {
        completion();
    } else {
        [self.dataStore
            removeUnreferencedArticlesFromDiskCacheWithFailure:^(NSError *_Nonnull error) {
                DDLogError(@"Error during article migration: %@", error);
                completion();
            }
            success:^{
                [[NSUserDefaults wmf] wmf_setDidMigrateToFixArticleCache:YES];
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

    if (self.notificationUserInfoToShow) {
        [self showInTheNewsForNotificationInfo:self.notificationUserInfoToShow];
        self.notificationUserInfoToShow = nil;
        done();
    } else if (self.unprocessedUserActivity) {
        [self processUserActivity:self.unprocessedUserActivity animated:NO completion:done];
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

    [[WMFDailyStatsLoggingFunnel shared] logAppNumberOfDaysSinceInstall];

    [[WMFAuthenticationManager sharedInstance]
        attemptLoginWithCompletion:^{
            [self checkRemoteAppConfigIfNecessary];
            if (!self.periodicWorkerController) {
                self.periodicWorkerController = [[WMFPeriodicWorkerController alloc] initWithInterval:30];
                [self.periodicWorkerController add:self.dataStore.readingListsController];
                [self.periodicWorkerController add:self.dataStore.remoteNotificationsController];
                [self.periodicWorkerController add:[WMFEventLoggingService sharedInstance]];
            }
            if (!self.backgroundFetcherController) {
                self.backgroundFetcherController = [[WMFBackgroundFetcherController alloc] init];
                [self.backgroundFetcherController add:self.dataStore.readingListsController];
                [self.backgroundFetcherController add:self.dataStore.remoteNotificationsController];
                [self.backgroundFetcherController add:(id<WMFBackgroundFetcher>)self.dataStore.feedContentController];
                [self.backgroundFetcherController add:[WMFEventLoggingService sharedInstance]];
            }
            if (!self.reachabilityNotifier) {
                @weakify(self);
                self.reachabilityNotifier = [[WMFReachabilityNotifier alloc] initWithHost:WMFDefaultSiteDomain
                                                                                 callback:^(BOOL isReachable, SCNetworkReachabilityFlags flags) {
                                                                                     @strongify(self);
                                                                                     @weakify(self);
                                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                                         @strongify(self);
                                                                                         if (isReachable) {
                                                                                             [self.savedArticlesFetcher start];
                                                                                         } else {
                                                                                             [self.savedArticlesFetcher stop];
                                                                                         }
                                                                                     });
                                                                                 }];
            }
            [self.periodicWorkerController start];
            [self.savedArticlesFetcher start];
            [self.reachabilityNotifier start];
            self.resumeComplete = YES;
        }
        failure:^(NSError *error) {
            if ([error.domain isEqualToString:NSURLErrorDomain]) {
                return;
            }
            [self wmf_showReloginFailedPanelIfNecessaryWithTheme:self.theme];
        }];

    [self.dataStore.feedContentController startContentSources];

    NSUserDefaults *defaults = [NSUserDefaults wmf];
    NSDate *feedRefreshDate = [defaults wmf_feedRefreshDate];
    NSDate *now = [NSDate date];

    BOOL locationAuthorized = [WMFLocationManager isAuthorized];
    if (!feedRefreshDate || [now timeIntervalSinceDate:feedRefreshDate] > [self timeBeforeRefreshingExploreFeed] || [[NSCalendar wmf_gregorianCalendar] wmf_daysFromDate:feedRefreshDate toDate:now] > 0) {
        [self.exploreViewController updateFeedSourcesWithDate:nil
                                                userInitiated:NO
                                                   completion:^{
                                                   }];
    } else if (locationAuthorized != [defaults wmf_locationAuthorized]) {
        [self.dataStore.feedContentController updateNearbyForce:NO completion:NULL];
    }

    [defaults wmf_setLocationAuthorized:locationAuthorized];

    [self.savedArticlesFetcher start];

#if DEBUG && WMF_SHOW_ALL_ALERTS
    [[WMFAlertManager sharedInstance] showErrorAlert:[NSError errorWithDomain:@"WMFTestDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: @"There was an error"}]
                                              sticky:YES
                               dismissPreviousAlerts:NO
                                         tapCallBack:^{
                                             [[WMFAlertManager sharedInstance] showWarningAlert:@"You have been warned about a thing that has a long explanation of why you were warned. You have been warned about a thing that has a long explanation of why you were warned."
                                                                                         sticky:YES
                                                                          dismissPreviousAlerts:NO
                                                                                    tapCallBack:^{
                                                                                        [[WMFAlertManager sharedInstance] showSuccessAlert:@"You are successful"
                                                                                                                                    sticky:YES
                                                                                                                     dismissPreviousAlerts:NO
                                                                                                                               tapCallBack:^{
                                                                                                                                   [[WMFAlertManager sharedInstance] showAlert:@"You have been notified" sticky:YES dismissPreviousAlerts:NO tapCallBack:NULL];
                                                                                                                               }];
                                                                                    }];
                                         }];
#endif
#if WMF_TWEAKS_ENABLED
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
#endif
}

- (NSTimeInterval)timeBeforeRefreshingExploreFeed {
    NSTimeInterval timeInterval = 2 * 60 * 60;
    NSString *key = [WMFFeedDayResponse WMFFeedDayResponseMaxAgeKey];
    NSNumber *value = [self.dataStore.viewContext wmf_numberValueForKey:key];
    if (value) {
        timeInterval = [value doubleValue];
    }
    return timeInterval;
}

- (void)pauseApp {
    [self logSessionEnd];

    if (![self uiIsLoaded]) {
        return;
    }

    [[NSUserDefaults wmf] wmf_setDidShowSyncDisabledPanel:NO];

    [self.reachabilityNotifier stop];
    [self.periodicWorkerController stop];
    [self.savedArticlesFetcher stop];

    // Show  all navigation bars so that users will always see search when they re-open the app
    NSArray<UINavigationController *> *allNavControllers = [self allNavigationControllers];
    for (UINavigationController *navC in allNavControllers) {
        UIViewController *vc = [navC visibleViewController];
        if ([vc respondsToSelector:@selector(ensureWikipediaSearchIsShowing)]) {
            [(id)vc ensureWikipediaSearchIsShowing];
        }
    }

    self.settingsViewController = nil;

    [self.dataStore.feedContentController stopContentSources];

    self.houseKeeper = [WMFDatabaseHouseKeeper new];
    //TODO: these tasks should be converted to async so we can end the background task as soon as possible
    [self.dataStore clearMemoryCache];

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
    self.settingsViewController = nil;
    [self.dataStore clearMemoryCache];
}

#pragma mark - Logging

- (void)logSessionEnd {
    [[SessionsFunnel shared] logSessionEnd];
    [[UserHistoryFunnel shared] logSnapshot];
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
        [self switchToSearch:NO];
        [self.searchViewController makeSearchBarBecomeFirstResponder];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeRandom]) {
        [self showRandomArticleAnimated:NO];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeNearby]) {
        [self showNearbyAnimated:NO];
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
        case WMFUserActivityTypeAppearanceSettings:
        case WMFUserActivityTypeContent:
        case WMFUserActivityTypeSpecialPage:
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

- (void)navigateToActivityNotification:(NSNotification *)note {
    id object = [note object];
    if ([object isKindOfClass:[NSUserActivity class]]) {
        [self processUserActivity:object
                         animated:YES
                       completion:^{
                       }];
    }
}

- (BOOL)processUserActivity:(NSUserActivity *)activity animated:(BOOL)animated completion:(dispatch_block_t)done {
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
    [self dismissPresentedViewControllers];

    WMFUserActivityType type = [activity wmf_type];
    switch (type) {
        case WMFUserActivityTypeExplore:
            [self setSelectedIndex:WMFAppTabTypeMain];
            [[self navigationControllerForTab:WMFAppTabTypeMain] popToRootViewControllerAnimated:animated];
            break;
        case WMFUserActivityTypePlaces: {
            [self setSelectedIndex:WMFAppTabTypePlaces];
            [[self navigationControllerForTab:WMFAppTabTypePlaces] popToRootViewControllerAnimated:animated];
            NSURL *articleURL = activity.wmf_articleURL;
            if (articleURL) {
                // For "View on a map" action to succeed, view mode has to be set to map.
                [[self placesViewController] updateViewModeToMap];
                [[self placesViewController] showArticleURL:articleURL];
            }
        } break;
        case WMFUserActivityTypeContent: {
            [self setSelectedIndex:WMFAppTabTypeMain];
            UINavigationController *navController = [self navigationControllerForTab:WMFAppTabTypeMain];
            [navController popToRootViewControllerAnimated:animated];
            NSURL *url = [activity wmf_contentURL];
            WMFContentGroup *group = [self.dataStore.viewContext contentGroupForURL:url];
            if (group) {
                UIViewController *vc = [group detailViewControllerWithDataStore:self.dataStore theme:self.theme];
                if (vc) {
                    [navController pushViewController:vc animated:animated];
                }
            } else {
                [self.exploreViewController updateFeedSourcesWithDate:nil
                                                        userInitiated:NO
                                                           completion:^{
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   WMFContentGroup *group = [self.dataStore.viewContext contentGroupForURL:url];
                                                                   if (group) {
                                                                       UIViewController *vc = [group detailViewControllerWithDataStore:self.dataStore theme:self.theme];
                                                                       if (vc) {
                                                                           [navController pushViewController:vc animated:NO];
                                                                       }
                                                                   }
                                                               });
                                                           }];
            }

        } break;
        case WMFUserActivityTypeSavedPages:
            [self setSelectedIndex:WMFAppTabTypeSaved];
            [[self navigationControllerForTab:WMFAppTabTypeSaved] popToRootViewControllerAnimated:animated];
            break;
        case WMFUserActivityTypeHistory:
            [self setSelectedIndex:WMFAppTabTypeRecent];
            [[self navigationControllerForTab:WMFAppTabTypeRecent] popToRootViewControllerAnimated:animated];
            break;
        case WMFUserActivityTypeSearch:
            [self showSearchInCurrentNavigationController];
            break;
        case WMFUserActivityTypeSearchResults:
            [self switchToSearch:YES];
            [self.searchViewController setSearchTerm:[activity wmf_searchTerm]];
            [self.searchViewController search];
            break;
        case WMFUserActivityTypeArticle: {
            NSURL *URL = [activity wmf_articleURL];
            if (!URL) {
                done();
                return NO;
            }
            [self showArticleForURL:URL animated:animated completion:done];
            // don't call done block before this return, wait for completion ^
            return YES;
        } break;
        case WMFUserActivityTypeSettings:
            [self setSelectedIndex:WMFAppTabTypeMain];
            [[self navigationControllerForTab:WMFAppTabTypeMain] popToRootViewControllerAnimated:NO];
            [self showSettingsAnimated:animated];
            break;
        case WMFUserActivityTypeAppearanceSettings: {
            [self setSelectedIndex:WMFAppTabTypeMain];
            [[self navigationControllerForTab:WMFAppTabTypeMain] popToRootViewControllerAnimated:NO];
            WMFAppearanceSettingsViewController *appearanceSettingsVC = [[WMFAppearanceSettingsViewController alloc] init];
            [appearanceSettingsVC applyTheme:self.theme];
            [self showSettingsWithSubViewController:appearanceSettingsVC animated:animated];
        } break;
        case WMFUserActivityTypeGenericLink:
            [self wmf_openExternalUrl:[activity wmf_articleURL]];
            break;
        case WMFUserActivityTypeSpecialPage:
            [self wmf_openExternalUrl:[activity wmf_contentURL]];
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

- (void)selectDefaultTabAndDismissPresentedViewControllers {
    [self dismissPresentedViewControllers];
    [self setSelectedIndex:WMFAppTabTypeMain];
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
    [self selectDefaultTabAndDismissPresentedViewControllers];
    return [self.exploreViewController wmf_pushArticleWithURL:articleURL dataStore:self.session.dataStore theme:self.theme restoreScrollPosition:YES animated:animated articleLoadCompletion:completion];
}

- (BOOL)shouldShowExploreScreenOnLaunch {
    NSDate *resignActiveDate = [[NSUserDefaults wmf] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeShowingExploreScreenOnLaunch) {
        return YES;
    }
    return NO;
}

- (BOOL)mainViewControllerIsDisplayingContent {
    return [self navigationControllerForTab:WMFAppTabTypeMain].viewControllers.count > 1;
}

- (WMFArticleViewController *)visibleArticleViewController {
    UINavigationController *navVC = [self navigationControllerForTab:self.selectedIndex];
    UIViewController *topVC = navVC.topViewController;
    if ([topVC isKindOfClass:[WMFArticleViewController class]]) {
        return (WMFArticleViewController *)topVC;
    }
    return nil;
}

- (UINavigationController *)navigationControllerForTab:(WMFAppTabType)tab {
    return (UINavigationController *)[self viewControllers][tab];
}

- (UIViewController *)rootViewControllerForTab:(WMFAppTabType)tab {
    return [[[self navigationControllerForTab:tab] viewControllers] firstObject];
}

#pragma mark - Accessors

- (SavedArticlesFetcher *)savedArticlesFetcher {
    if (![self uiIsLoaded]) {
        return nil;
    }
    if (!_savedArticlesFetcher) {
        _savedArticlesFetcher = [[SavedArticlesFetcher alloc] initWithDataStore:[[SessionSingleton sharedInstance] dataStore]];
        [_savedArticlesFetcher addObserver:self forKeyPath:WMF_SAFE_KEYPATH(_savedArticlesFetcher, progress) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:&kvo_SavedArticlesFetcher_progress];
    }
    return _savedArticlesFetcher;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &kvo_SavedArticlesFetcher_progress) {
        [ProgressContainer shared].articleFetcherProgress = _savedArticlesFetcher.progress;
    } else if (context == &kvo_NSUserDefaults_defaultTabType) {
        [self updateDefaultTab];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

- (ExploreViewController *)exploreViewController {
    if (!_exploreViewController) {
        _exploreViewController = [[ExploreViewController alloc] init];
        _exploreViewController.dataStore = self.dataStore;
    }
    return _exploreViewController;
}

- (SearchViewController *)searchViewController {
    if (!_searchViewController) {
        _searchViewController = [[SearchViewController alloc] init];
        [_searchViewController applyTheme:self.theme];
        _searchViewController.dataStore = self.dataStore;
    }
    return _searchViewController;
}

- (WMFSavedViewController *)savedViewController {
    if (!_savedViewController) {
        _savedViewController = [[UIStoryboard storyboardWithName:@"Saved" bundle:nil] instantiateInitialViewController];
        [_savedViewController applyTheme:self.theme];
        _savedViewController.dataStore = self.dataStore;
    }
    return _savedViewController;
}

- (WMFHistoryViewController *)recentArticlesViewController {
    if (!_recentArticlesViewController) {
        _recentArticlesViewController = [[WMFHistoryViewController alloc] init];
        [_recentArticlesViewController applyTheme:self.theme];
        _recentArticlesViewController.dataStore = self.dataStore;
    }
    return _recentArticlesViewController;
}

- (WMFPlacesViewController *)placesViewController {
    if (!_placesViewController) {
        _placesViewController = [[UIStoryboard storyboardWithName:@"Places" bundle:nil] instantiateInitialViewController];
        _placesViewController.dataStore = self.dataStore;
        [_placesViewController applyTheme:self.theme];
    }
    return _placesViewController;
}

#pragma mark - Onboarding

static NSString *const WMFDidShowOnboarding = @"DidShowOnboarding5.3";

- (BOOL)shouldShowOnboarding {
#if WMF_TWEAKS_ENABLED
    if (FBTweakValue(@"Welcome", @"General", @"Show on launch (requires force quit)", NO) || [[NSProcessInfo processInfo] environment][@"WMFShowWelcomeView"].boolValue) {
        return YES;
    }
#endif

    NSNumber *didShow = [[NSUserDefaults wmf] objectForKey:WMFDidShowOnboarding];
    return !didShow.boolValue;
}

- (void)setDidShowOnboarding {
    [[NSUserDefaults wmf] setObject:@YES forKey:WMFDidShowOnboarding];
}

- (void)presentOnboardingIfNeededWithCompletion:(void (^)(BOOL didShowOnboarding))completion {
    if ([self shouldShowOnboarding]) {
        WMFWelcomeInitialViewController *vc = [WMFWelcomeInitialViewController wmf_viewControllerFromWelcomeStoryboard];

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

- (UIImageView *)splashView {
    if (!_splashView) {
        _splashView = [[UIImageView alloc] init];
        _splashView.contentMode = UIViewContentModeCenter;
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
            [_splashView setImage:[UIImage imageNamed:@"splashscreen-background"]];
        }
        _splashView.backgroundColor = [UIColor whiteColor];
        [self.view wmf_addSubviewWithConstraintsToEdges:_splashView];
        UIImage *wordmark = [UIImage imageNamed:@"wikipedia-wordmark"];
        UIImageView *wordmarkView = [[UIImageView alloc] initWithImage:wordmark];
        wordmarkView.translatesAutoresizingMaskIntoConstraints = NO;
        [_splashView addSubview:wordmarkView];
        NSLayoutConstraint *centerXConstraint = [_splashView.centerXAnchor constraintEqualToAnchor:wordmarkView.centerXAnchor];
        NSLayoutConstraint *centerYConstraint = [_splashView.centerYAnchor constraintEqualToAnchor:wordmarkView.centerYAnchor constant:12];
        [_splashView addConstraints:@[centerXConstraint, centerYConstraint]];
    }
    return _splashView;
}

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
    [self setSelectedIndex:WMFAppTabTypeMain];
    [[self navigationControllerForTab:WMFAppTabTypeMain] popToRootViewControllerAnimated:NO];
}

#pragma mark - Last Read Article

- (BOOL)shouldShowLastReadArticleOnLaunch {
    NSURL *lastRead = [[NSUserDefaults wmf] wmf_openArticleURL];
    if (!lastRead) {
        return NO;
    }

#if WMF_TWEAKS_ENABLED
    if (FBTweakValue(@"Last Open Article", @"General", @"Restore on Launch", YES)) {
        return YES;
    }

    NSDate *resignActiveDate = [[NSUserDefaults wmf] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) < WMFTimeBeforeShowingExploreScreenOnLaunch) {
        if (![self mainViewControllerIsDisplayingContent] && [self selectedIndex] == WMFAppTabTypeMain) {
            return YES;
        }
    }

    return NO;
#else
    return YES;
#endif
}

- (void)showLastReadArticleAnimated:(BOOL)animated {
    NSURL *lastRead = [[NSUserDefaults wmf] wmf_openArticleURL];
    [self showArticleForURL:lastRead animated:animated];
}

#pragma mark - Show Search

- (void)switchToSearch:(BOOL)animated {
    [self dismissPresentedViewControllers];
    if (self.selectedIndex != WMFAppTabTypeSearch) {
        [self setSelectedIndex:WMFAppTabTypeSearch];
    }
}

#pragma mark - App Shortcuts

- (void)dismissPresentedViewControllers {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:NULL];
    }

    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeMain];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }

    UINavigationController *placesNavigationController = [self navigationControllerForTab:WMFAppTabTypePlaces];
    if (placesNavigationController.presentedViewController) {
        [placesNavigationController dismissViewControllerAnimated:NO completion:NULL];
    }
}
- (void)showRandomArticleAnimated:(BOOL)animated {
    [self dismissPresentedViewControllers];
    [self setSelectedIndex:WMFAppTabTypeMain];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeMain];

    WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:[self siteURL] dataStore:self.dataStore theme:self.theme];
    [vc applyTheme:self.theme];
    [exploreNavController pushViewController:vc animated:animated];
}

- (void)showNearbyAnimated:(BOOL)animated {
    [self dismissPresentedViewControllers];

    [self setSelectedIndex:WMFAppTabTypePlaces];
    UINavigationController *placesNavigationController = [self navigationControllerForTab:WMFAppTabTypePlaces];

    [placesNavigationController popToRootViewControllerAnimated:NO];

    [[self placesViewController] showNearbyArticles];
}

#pragma mark - App config

- (void)checkRemoteAppConfigIfNecessary {
    WMFAssertMainThread(@"Remote app config check must start from the main thread");
    if (self.isCheckingRemoteConfig) {
        return;
    }
    self.checkingRemoteConfig = YES;
    CFAbsoluteTime lastCheckTime = (CFAbsoluteTime)[[self.dataStore.viewContext wmf_numberValueForKey:WMFLastRemoteAppConfigCheckAbsoluteTimeKey] doubleValue];
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (now - lastCheckTime >= WMFRemoteAppConfigCheckInterval) {
        [self.dataStore updateLocalConfigurationFromRemoteConfigurationWithCompletion:^(NSError *error) {
            if (!error) {
                [self.dataStore.viewContext wmf_setValue:[NSNumber numberWithDouble:now] forKey:WMFLastRemoteAppConfigCheckAbsoluteTimeKey];
            }
            self.checkingRemoteConfig = NO;
        }];
    } else {
        self.checkingRemoteConfig = NO;
    }
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self wmf_hideKeyboard];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (viewController == tabBarController.selectedViewController) {
        switch (tabBarController.selectedIndex) {
            case WMFAppTabTypeMain: {
                ExploreViewController *exploreViewController = (ExploreViewController *)[self exploreViewController];
                [exploreViewController scrollToTop];
            } break;
        }
    }
    if ([viewController isKindOfClass:[WMFArticleNavigationController class]]) {
        [(WMFArticleNavigationController *)viewController popToRootViewControllerAnimated:NO];
    }
    return YES;
}

- (void)updateActiveTitleAccessibilityButton:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[ExploreViewController class]]) {
        ExploreViewController *vc = (ExploreViewController *)viewController;
        vc.titleButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-title-accessibility-label", nil, nil, @"Wikipedia, scroll to top of Explore", @"Accessibility heading for the Explore page, indicating that tapping it will scroll to the top of the explore page. \"Explore\" is the same as {{msg-wikimedia|Wikipedia-ios-welcome-explore-title}}.");
    } else if ([viewController isKindOfClass:[WMFArticleViewController class]]) {
        WMFArticleViewController *vc = (WMFArticleViewController *)viewController;
        if (self.selectedIndex == WMFAppTabTypeMain) {
            vc.titleButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-button-explore-accessibility-label", nil, nil, @"Wikipedia, return to Explore", @"Accessibility heading for articles shown within the explore tab, indicating that tapping it will take you back to explore. \"Explore\" is the same as {{msg-wikimedia|Wikipedia-ios-welcome-explore-title}}.");
        } else if (self.selectedIndex == WMFAppTabTypeSaved) {
            vc.titleButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-button-saved-accessibility-label", nil, nil, @"Wikipedia, return to Saved", @"Accessibility heading for articles shown within the saved articles tab, indicating that tapping it will take you back to the list of saved articles. \"Saved\" is the same as {{msg-wikimedia|Wikipedia-ios-saved-title}}.");
        } else if (self.selectedIndex == WMFAppTabTypeRecent) {
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
    if ([viewController conformsToProtocol:@protocol(WMFSearchButtonProviding)] && viewController.navigationItem.rightBarButtonItem == nil) {
        WMFSearchButton *searchButton = [[WMFSearchButton alloc] initWithTarget:self action:@selector(showSearchInCurrentNavigationController)];
        viewController.navigationItem.rightBarButtonItem = searchButton;
        if ([viewController isKindOfClass:[ExploreViewController class]]) {
            viewController.navigationItem.rightBarButtonItem.customView.alpha = 0;
        }
    }
    [self updateActiveTitleAccessibilityButton:viewController];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([[navigationController viewControllers] count] == 1) {
        [[NSUserDefaults wmf] wmf_setOpenArticleURL:nil];
    }

    NSArray *viewControllers = navigationController.viewControllers;
    NSInteger count = viewControllers.count;
    NSMutableIndexSet *indiciesToRemove = [NSMutableIndexSet indexSet];
    NSInteger index = 1;
    NSInteger limit = count - 2;
    while (index < limit) {
        if ([viewControllers[index] isKindOfClass:[SearchViewController class]]) {
            [indiciesToRemove addIndex:index];
        }
        index++;
    }

    if (indiciesToRemove.count > 0) {
        NSMutableArray *mutableViewControllers = [navigationController.viewControllers mutableCopy];
        [mutableViewControllers removeObjectsAtIndexes:indiciesToRemove];
        [navigationController setViewControllers:mutableViewControllers animated:NO];
    }
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    return [self.transitionsController navigationController:navigationController interactionControllerForAnimationController:animationController];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    return [self.transitionsController navigationController:navigationController animationControllerForOperation:operation fromViewController:fromVC toViewController:toVC];
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
    [[NSUserDefaults wmf] setBool:YES forKey:WMFZeroOnDialogShownOnce];
}

- (BOOL)zeroOnDialogShownOnce {
    return [[NSUserDefaults wmf] boolForKey:WMFZeroOnDialogShownOnce];
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
                                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://foundation.m.wikimedia.org/wiki/Wikipedia_Zero_App_FAQ"] options:@{} completionHandler:NULL];
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
    UNNotificationContent *notificationContent = notification.request.content;
    NSString *categoryIdentifier = notificationContent.categoryIdentifier;
    NSString *notificationID = (NSString *)notificationContent.userInfo[WMFEditRevertedNotificationIDKey];
    if ([categoryIdentifier isEqualToString:WMFEditRevertedNotificationCategoryIdentifier]) {
        [self.remoteNotificationsModelChangeResponseCoordinator markAsSeenNotificationWithID:notificationID];
    }
}

// The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
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
            [self showInTheNewsForNotificationInfo:info];
        } else if ([actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
        }
        // WMFEditRevertedNotification
    } else if ([categoryIdentifier isEqualToString:WMFEditRevertedNotificationCategoryIdentifier]) {
        NSDictionary *info = response.notification.request.content.userInfo;
        NSString *articleURLString = (NSString *)info[WMFNotificationInfoArticleURLStringKey];
        NSString *notificationID = (NSString *)info[WMFEditRevertedNotificationIDKey];
        assert(articleURLString);
        assert(notificationID);
        if ([actionIdentifier isEqualToString:WMFEditRevertedReadMoreActionIdentifier] || [actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
            NSURL *articleURL = [NSURL URLWithString:articleURLString];
            assert(articleURL);
            [self showReadMoreAboutRevertedEditViewControllerWithArticleURL:articleURL
                                                                 completion:^{
                                                                     [self.remoteNotificationsModelChangeResponseCoordinator markAsReadNotificationWithID:notificationID];
                                                                 }];
        } else {
            [self.remoteNotificationsModelChangeResponseCoordinator markAsReadNotificationWithID:notificationID];
        }
    }

    completionHandler();
}

- (void)showInTheNewsForNotificationInfo:(NSDictionary *)info {
    if (!self.isMigrationComplete) {
        self.notificationUserInfoToShow = info;
        return;
    }
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
    [self selectDefaultTabAndDismissPresentedViewControllers];

    if (!feedNewsStory) {
        return;
    }

    UIViewController *vc = [[WMFNewsViewController alloc] initWithStories:@[feedNewsStory] dataStore:self.dataStore contentGroup:nil theme:self.theme];
    if (!vc) {
        return;
    }

    [self setSelectedIndex:WMFAppTabTypeMain];
    UINavigationController *navController = [self navigationControllerForTab:WMFAppTabTypeMain];
    [navController popToRootViewControllerAnimated:NO];
    [navController pushViewController:vc animated:NO];
}

#pragma mark - Themeable

- (void)applyTheme:(WMFTheme *)theme toNavigationControllers:(NSArray<UINavigationController *> *)navigationControllers {
    NSMutableSet<UINavigationController *> *foundNavigationControllers = [NSMutableSet setWithCapacity:1];
    for (UINavigationController *nc in navigationControllers) {
        for (UIViewController *vc in nc.viewControllers) {
            if ([vc conformsToProtocol:@protocol(WMFThemeable)]) {
                [(id<WMFThemeable>)vc applyTheme:theme];
            }
            if ([vc.presentedViewController isKindOfClass:[UINavigationController class]]) {
                [foundNavigationControllers addObject:(UINavigationController *)vc.presentedViewController];
            }
        }

        if ([nc.presentedViewController isKindOfClass:[UINavigationController class]]) {
            [foundNavigationControllers addObject:(UINavigationController *)nc.presentedViewController];
        }

        if ([nc conformsToProtocol:@protocol(WMFThemeable)]) {
            [(id<WMFThemeable>)nc applyTheme:theme];
        }
    }

    [[UITextField appearanceWhenContainedInInstancesOfClasses:@ [[UISearchBar class]]] setTextColor:theme.colors.primaryText];

    if ([foundNavigationControllers count] > 0) {
        [self applyTheme:theme toNavigationControllers:[foundNavigationControllers allObjects]];
    }
}

- (NSArray<UINavigationController *> *)allNavigationControllers {
    // Navigation controllers
    NSMutableArray<UINavigationController *> *navigationControllers = [NSMutableArray arrayWithObjects:[self navigationControllerForTab:WMFAppTabTypeMain], [self navigationControllerForTab:WMFAppTabTypePlaces], [self navigationControllerForTab:WMFAppTabTypeSaved], [self navigationControllerForTab:WMFAppTabTypeRecent], [self navigationControllerForTab:WMFAppTabTypeSearch], nil];
    if (self.settingsNavigationController) {
        [navigationControllers addObject:self.settingsNavigationController];
    }
    return navigationControllers;
}

- (void)applyTheme:(WMFTheme *)theme {
    if (theme == nil) {
        return;
    }
    self.theme = theme;

    self.view.backgroundColor = theme.colors.baseBackground;
    self.view.tintColor = theme.colors.link;

    [self.searchViewController applyTheme:theme];
    [self.settingsViewController applyTheme:theme];

    [[WMFAlertManager sharedInstance] applyTheme:theme];

    [self applyTheme:theme toNavigationControllers:[self allNavigationControllers]];

    // Tab bars

    NSArray<UITabBar *> *tabBars = @[self.tabBar, [UITabBar appearance]];
    NSMutableArray<UITabBarItem *> *tabBarItems = [NSMutableArray arrayWithCapacity:5];
    for (UITabBar *tabBar in tabBars) {
        [tabBar applyTheme:theme];
        if (tabBar.items.count > 0) {
            [tabBarItems addObjectsFromArray:tabBar.items];
        }
    }

    // Tab bar items
    for (UITabBarItem *item in tabBarItems) {
        [item applyTheme:theme];
    }

    [[UISwitch appearance] setOnTintColor:theme.colors.accent];

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)changeTheme:(NSNotification *)note {
    WMFTheme *theme = (WMFTheme *)note.userInfo[WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationThemeKey];

    if (self.theme != theme) {
        [self applyTheme:theme];
        [[NSUserDefaults wmf] wmf_setAppTheme:theme];
        [self.settingsViewController loadSections];
    }
}

#pragma mark - Article save to disk did fail

- (void)articleSaveToDiskDidFail:(NSNotification *)note {
    NSError *error = (NSError *)note.userInfo[WMFArticleSaveToDiskDidFailErrorKey];
    if (error.domain == NSCocoaErrorDomain && error.code == NSFileWriteOutOfSpaceError) {
        [[WMFAlertManager sharedInstance] showErrorAlertWithMessage:WMFLocalizedStringWithDefaultValue(@"article-save-error-not-enough-space", nil, nil, @"You do not have enough space on your device to save this article", @"Alert message informing user that article cannot be save due to insufficient storage available")
                                                             sticky:YES
                                              dismissPreviousAlerts:YES
                                                        tapCallBack:nil];
    }
}

#pragma mark - Appearance

- (void)articleFontSizeWasUpdated:(NSNotification *)note {
    NSNumber *multiplier = (NSNumber *)note.userInfo[WMFFontSizeSliderViewController.WMFArticleFontSizeMultiplierKey];
    [[NSUserDefaults wmf] wmf_setArticleFontSizeMultiplier:multiplier];
}

#pragma mark - Search

- (void)showSearchInCurrentNavigationController {
    [self showSearchInCurrentNavigationControllerAnimated:YES];
}

- (void)showSettings {
    [self showSettingsAnimated:YES];
}

- (void)dismissReadingThemesPopoverIfActive {
    if ([self.presentedViewController isKindOfClass:[WMFReadingThemesControlsViewController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)showSearchInCurrentNavigationControllerAnimated:(BOOL)animated {
    NSParameterAssert(self.dataStore);

    [self dismissReadingThemesPopoverIfActive];

    id vc = [self selectedViewController];
    if (![vc isKindOfClass:[UINavigationController class]]) {
        return;
    }

    UINavigationController *nc = (UINavigationController *)vc;
    NSArray *vcs = nc.viewControllers;
    NSMutableArray *mutableVCs = [vcs mutableCopy];
    SearchViewController *searchVC = nil;
    NSInteger index = 1;
    NSInteger limit = vcs.count;
    while (index < limit) {
        UIViewController *vc = vcs[index];
        if ([vc isKindOfClass:[SearchViewController class]]) {
            searchVC = (SearchViewController *)vc;
            [mutableVCs removeObjectAtIndex:index];
            break;
        }
        index++;
    }

    if (searchVC) {
        [searchVC clear]; // clear search VC before bringing it forward
        [nc setViewControllers:mutableVCs animated:NO];
    } else {
        searchVC = [[SearchViewController alloc] init];
        searchVC.shouldBecomeFirstResponder = YES;
        searchVC.areRecentSearchesEnabled = NO;
        [searchVC applyTheme:self.theme];
        searchVC.dataStore = self.dataStore;
    }

    [vc pushViewController:searchVC animated:true];
}

- (nonnull WMFSettingsViewController *)settingsViewController {
    if (!_settingsViewController) {
        WMFSettingsViewController *settingsVC =
            [WMFSettingsViewController settingsViewControllerWithDataStore:self.dataStore];
        [settingsVC applyTheme:self.theme];
        _settingsViewController = settingsVC;
    }
    return _settingsViewController;
}

- (nonnull UINavigationController *)settingsNavigationController {
    if (!_settingsNavigationController) {
        WMFThemeableNavigationController *navController = [[WMFThemeableNavigationController alloc] initWithRootViewController:self.settingsViewController theme:self.theme];
        [self applyTheme:self.theme toNavigationControllers:@[navController]];
        _settingsNavigationController = navController;
    }

    if (_settingsNavigationController.viewControllers.count == 0) {
        _settingsNavigationController.viewControllers = @[self.settingsViewController];
    }

    return _settingsNavigationController;
}

- (void)showSettingsWithSubViewController:(nullable UIViewController *)subViewController animated:(BOOL)animated {
    NSParameterAssert(self.dataStore);
    [self dismissPresentedViewControllers];

    if (subViewController) {
        [self.settingsNavigationController pushViewController:subViewController animated:NO];
    }

    [self presentViewController:self.settingsNavigationController animated:animated completion:nil];
}

- (void)showSettingsAnimated:(BOOL)animated {
    [self showSettingsWithSubViewController:nil animated:animated];
}

#pragma mark - WMFReadingListsAlertPresenter

- (void)entriesLimitReachedWithNotification:(NSNotification *)notification {
    ReadingList *readingList = (ReadingList *)notification.userInfo[ReadingList.entriesLimitReachedReadingListKey];
    if (readingList) {
        [self.readingListsAlertController showLimitHitForDefaultListPanelIfNecessaryWithPresenter:self dataStore:self.dataStore readingList:readingList theme:self.theme];
    }
}

#pragma mark - Remote Notifications

- (void)remoteNotificationsModelDidChange:(NSNotification *)note {
    self.remoteNotificationsModelChangeResponseCoordinator = (RemoteNotificationsModelChangeResponseCoordinator *)note.object;
    assert(self.remoteNotificationsModelChangeResponseCoordinator);
    RemoteNotificationsModelChange *modelChange = (RemoteNotificationsModelChange *)self.remoteNotificationsModelChangeResponseCoordinator.modelChange;
    NSDictionary<NSNumber *, NSArray<RemoteNotification *> *> *notificationsGroupedByCategoryNumber = (NSDictionary<NSNumber *, NSArray<RemoteNotification *> *> *)modelChange.notificationsGroupedByCategoryNumber;
    assert(modelChange);
    switch (modelChange.type) {
        case RemoteNotificationsModelChangeTypeAddedNewNotifications:
        case RemoteNotificationsModelChangeTypeUpdatedExistingNotifications:
            [self scheduleLocalNotificationsForRemoteNotificationsWithCategory:RemoteNotificationCategoryEditReverted notificationsGroupedByCategoryNumber:notificationsGroupedByCategoryNumber];
        default:
            break;
    }
}

- (void)scheduleLocalNotificationsForRemoteNotificationsWithCategory:(RemoteNotificationCategory)category notificationsGroupedByCategoryNumber:(NSDictionary<NSNumber *, NSArray<RemoteNotification *> *> *)notificationsGroupedByCategoryNumber {
    NSAssert(category == RemoteNotificationCategoryEditReverted, @"Categories other than RemoteNotificationCategoryEditReverted are not supported");

    NSNumber *editRevertedCategoryNumber = [NSNumber numberWithInt:RemoteNotificationCategoryEditReverted];
    NSArray<RemoteNotification *> *editRevertedNotifications = notificationsGroupedByCategoryNumber[editRevertedCategoryNumber];
    if (editRevertedNotifications.count == 0) {
        return;
    }

    for (RemoteNotification *editRevertedNotification in editRevertedNotifications) {
        WMFArticle *article = [self.dataStore fetchArticleWithWikidataID:editRevertedNotification.affectedPageID];
        if (!article || !article.displayTitle || !article.URL || !editRevertedNotification.agent) {
            // Exclude notifications without article context or notification agent
            [self.remoteNotificationsModelChangeResponseCoordinator markAsExcluded:editRevertedNotification];
        } else {
            NSString *articleTitle = article.displayTitle;
            NSString *agent = editRevertedNotification.agent;

            NSString *notificationTitle = [WMFCommonStrings revertedEditTitle];
            NSString *notificationBodyFormat = WMFLocalizedStringWithDefaultValue(@"reverted-edit-notification-body", nil, nil, @"The edit you made of the article %1$@ was reverted by %2$@", @"Title for notification telling user that the edit they made was reverted. %1$@ is replaced with the title of the affected article, %2$@ is replaced with the username of the person who reverted the edit.");
            NSString *notificationBody = [NSString localizedStringWithFormat:notificationBodyFormat, articleTitle, agent];

            NSDictionary *userInfo = @{WMFNotificationInfoArticleURLStringKey: article.URL.absoluteString, WMFEditRevertedNotificationIDKey: editRevertedNotification.id};
            [self.notificationsController sendNotificationWithTitle:notificationTitle body:notificationBody categoryIdentifier:WMFEditRevertedNotificationCategoryIdentifier userInfo:userInfo atDateComponents:nil];
        }
    }
}

- (void)showReadMoreAboutRevertedEditViewControllerWithArticleURL:(NSURL *)articleURL completion:(void (^)(void))completion {
    ReadMoreAboutRevertedEditViewController *readMoreViewController = [[ReadMoreAboutRevertedEditViewController alloc] initWithNibName:@"ReadMoreAboutRevertedEditViewController" bundle:nil];
    readMoreViewController.delegate = self;
    readMoreViewController.articleURL = articleURL;
    WMFThemeableNavigationController *navController = [[WMFThemeableNavigationController alloc] initWithRootViewController:readMoreViewController theme:self.theme];
    [self presentViewController:navController animated:YES completion:completion];
}

- (void)readMoreAboutRevertedEditViewControllerDidPressGoToArticleButton:(nonnull NSURL *)articleURL {
    [self showArticleForURL:articleURL animated:YES];
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
    UINavigationController *navController = [self navigationControllerForTab:WMFAppTabTypeMain];
    if ([navController.visibleViewController isKindOfClass:[WMFRandomArticleViewController class]] || [navController.visibleViewController isKindOfClass:[WMFFirstRandomViewController class]]) {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        return;
    }

    [self setSelectedIndex:WMFAppTabTypeMain];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeMain];

    [self dismissPresentedViewControllers];

    WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:[self siteURL] dataStore:self.dataStore theme:self.theme];
    vc.permaRandomMode = NO;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [exploreNavController pushViewController:vc animated:YES];
}
#endif

@end
