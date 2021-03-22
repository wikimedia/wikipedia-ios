#import "WMFAppViewController.h"
@import WMF;
@import SystemConfiguration;
#import "Wikipedia-Swift.h"

#define DEBUG_THEMES 1

// Views
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"

// View Controllers
#import "WMFSettingsViewController.h"
#import "WMFFirstRandomViewController.h"

#import "AppDelegate.h"

#import "WMFDailyStatsLoggingFunnel.h"

#import "Wikipedia-Swift.h"
#import "EXTScope.h"

/**
 *  Enums for each tab in the main tab bar.
 */
typedef NS_ENUM(NSUInteger, WMFAppTabType) {
    WMFAppTabTypeMain = 0,
    WMFAppTabTypePlaces = 1,
    WMFAppTabTypeSaved = 2,
    WMFAppTabTypeRecent = 3,
    WMFAppTabTypeSearch = 4
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

static NSTimeInterval const WMFTimeBeforeShowingExploreScreenOnLaunch = 24 * 60 * 60;

static CFTimeInterval const WMFRemoteAppConfigCheckInterval = 3 * 60 * 60;
static NSString *const WMFLastRemoteAppConfigCheckAbsoluteTimeKey = @"WMFLastRemoteAppConfigCheckAbsoluteTimeKey";

static const NSString *kvo_NSUserDefaults_defaultTabType = @"kvo_NSUserDefaults_defaultTabType";
static const NSString *kvo_SavedArticlesFetcher_progress = @"kvo_SavedArticlesFetcher_progress";

@interface WMFAppViewController () <UITabBarControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, WMFThemeable, ReadMoreAboutRevertedEditViewControllerDelegate, WMFWorkerControllerDelegate, WMFThemeableNavigationControllerDelegate, WMFAppTabBarDelegate>

@property (nonatomic, strong) WMFPeriodicWorkerController *periodicWorkerController;
@property (nonatomic, strong) WMFBackgroundFetcherController *backgroundFetcherController;
@property (nonatomic, strong) WMFReachabilityNotifier *reachabilityNotifier;

@property (nonatomic, strong) WMFViewControllerTransitionsController *transitionsController;

@property (nonatomic, strong) WMFSettingsViewController *settingsViewController;
@property (nonatomic, strong, readonly) ExploreViewController *exploreViewController;
@property (nonatomic, strong, readonly) SearchViewController *searchViewController;
@property (nonatomic, strong, readonly) WMFSavedViewController *savedViewController;
@property (nonatomic, strong, readonly) WMFPlacesViewController *placesViewController;
@property (nonatomic, strong, readonly) WMFHistoryViewController *recentArticlesViewController;

@property (nonatomic, strong) WMFSavedArticlesFetcher *savedArticlesFetcher;

@property (nonatomic, strong) WMFMobileViewToMobileHTMLMigrationController *mobileViewToMobileHTMLMigrationController;

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;

@property (nonatomic, strong) WMFDatabaseHouseKeeper *houseKeeper;

@property (nonatomic) BOOL isPresentingOnboarding;

@property (nonatomic, strong) NSUserActivity *unprocessedUserActivity;
@property (nonatomic, strong) UIApplicationShortcutItem *unprocessedShortcutItem;

@property (nonatomic, strong) NSMutableDictionary *backgroundTasks;

@property (nonatomic, strong) WMFNotificationsController *notificationsController;

@property (nonatomic, getter=isWaitingToResumeApp) BOOL waitingToResumeApp;
@property (nonatomic, getter=isMigrationComplete) BOOL migrationComplete;
@property (nonatomic, getter=isMigrationActive) BOOL migrationActive;
@property (nonatomic, getter=isResumeComplete) BOOL resumeComplete; //app has fully loaded & login was attempted

@property (nonatomic, getter=isCheckingRemoteConfig) BOOL checkingRemoteConfig;

@property (nonatomic, copy) NSDictionary *notificationUserInfoToShow;

@property (nonatomic, strong) WMFTheme *theme;

@property (nonatomic, strong) UINavigationController *settingsNavigationController;

@property (nonatomic, strong, readwrite) WMFReadingListsAlertController *readingListsAlertController;

@property (nonatomic, strong, readwrite) NSDate *syncStartDate;

@property (nonatomic, strong) SavedTabBarItemProgressBadgeManager *savedTabBarItemProgressBadgeManager;

@property (nonatomic) BOOL hasSyncErrorBeenShownThisSesssion;

@property (nonatomic, strong) RemoteNotificationsModelChangeResponseCoordinator *remoteNotificationsModelChangeResponseCoordinator;

@property (nonatomic, strong) WMFReadingListHintController *readingListHintController;
@property (nonatomic, strong) WMFEditHintController *editHintController;

@property (nonatomic, strong) WMFNavigationStateController *navigationStateController;
@property (nonatomic, strong) WMFTalkPageReplyHintController *talkPageReplyHintController;
@property (nonatomic, strong) WMFTalkPageTopicHintController *talkPageTopicHintController;

@property (nonatomic, strong) WMFConfiguration *configuration;
@property (nonatomic, strong) WMFViewControllerRouter *router;

@end

@implementation WMFAppViewController
@synthesize exploreViewController = _exploreViewController;
@synthesize searchViewController = _searchViewController;
@synthesize savedViewController = _savedViewController;
@synthesize recentArticlesViewController = _recentArticlesViewController;
@synthesize placesViewController = _placesViewController;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:[WMFUserDefaultsKey defaultTabType]];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.configuration = [WMFConfiguration current];
        self.router = [[WMFViewControllerRouter alloc] initWithAppViewController:self router:self.configuration.router];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.theme = [[NSUserDefaults standardUserDefaults] themeCompatibleWith:self.traitCollection];

    self.backgroundTasks = [NSMutableDictionary dictionaryWithCapacity:5];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navigateToActivityNotification:)
                                                 name:WMFNavigateToActivityNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidChangeTheme:)
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
                                                 name:[WMFSavedArticlesFetcher saveToDiskDidFail]
                                               object:nil];

    [[NSUserDefaults standardUserDefaults] addObserver:self
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userWasLoggedOut:)
                                                 name:[WMFAuthenticationManager didLogOutNotification]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editWasPublished:)
                                                 name:[WMFSectionEditorViewController editWasPublished]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(descriptionEditWasPublished:)
                                                 name:[DescriptionEditViewController didPublishNotification]
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(talkPageReplyWasPublished:) name:WMFTalkPageContainerViewController.WMFReplyPublishedNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(talkPageTopicWasPublished:) name:WMFTalkPageContainerViewController.WMFTopicPublishedNotificationName object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(referenceLinkTapped:) name:WMFReferenceLinkTappedNotification object:nil];

    [self setupReadingListsHelpers];
    self.editHintController = [[WMFEditHintController alloc] init];
    self.talkPageReplyHintController = [[WMFTalkPageReplyHintController alloc] init];
    self.talkPageTopicHintController = [[WMFTalkPageTopicHintController alloc] init];
    if (@available(iOS 14.0, *)) {
        self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeGeneric;
    }
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
    return self.dataStore.primarySiteURL;
}

#pragma mark - Setup

- (void)setupControllers {
    self.periodicWorkerController = [[WMFPeriodicWorkerController alloc] initWithInterval:30 initialDelay:1 leeway:15];
    self.periodicWorkerController.delegate = self;
    [self.periodicWorkerController add:self.dataStore.readingListsController];
    [self.periodicWorkerController add:self.dataStore.remoteNotificationsController];
    [self.periodicWorkerController add:[WMFEventLoggingService sharedInstance]];
    [self.periodicWorkerController add:[WMFEventPlatformClient sharedInstance]];

    self.backgroundFetcherController = [[WMFBackgroundFetcherController alloc] init];
    self.backgroundFetcherController.delegate = self;
    [self.backgroundFetcherController add:self.dataStore.readingListsController];
    [self.backgroundFetcherController add:self.dataStore.remoteNotificationsController];
    [self.backgroundFetcherController add:(id<WMFBackgroundFetcher>)self.dataStore.feedContentController];
    [self.backgroundFetcherController add:[WMFEventLoggingService sharedInstance]];
    [self.backgroundFetcherController add:[WMFEventPlatformClient sharedInstance]];
}

- (void)loadMainUI {
    if ([self uiIsLoaded]) {
        return;
    }

    [self configureTabController];

    self.tabBar.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;

    [self applyTheme:self.theme];

    self.transitionsController = [WMFViewControllerTransitionsController new];

    self.recentArticlesViewController.dataStore = self.dataStore;
    [self.searchViewController applyTheme:self.theme];
    [self.settingsViewController applyTheme:self.theme];

    UITabBarItem *savedTabBarItem = [self.savedViewController tabBarItem];
    self.savedTabBarItemProgressBadgeManager = [[SavedTabBarItemProgressBadgeManager alloc] initWithTabBarItem:savedTabBarItem];

    [self.dataStore.notificationsController updateCategories];
}

- (void)configureTabController {
    self.delegate = self;

    UIViewController *mainViewController = nil;

    switch ([NSUserDefaults standardUserDefaults].defaultTabType) {
        case WMFAppDefaultTabTypeSettings:
            mainViewController = self.settingsViewController;
            break;
        default:
            mainViewController = self.exploreViewController;
            break;
    }

    NSArray<UIViewController *> *viewControllers = @[mainViewController, [self placesViewController], [self savedViewController], [self recentArticlesViewController], [self searchViewController]];

    [self setViewControllers:viewControllers animated:NO];

    BOOL shouldOpenAppOnSearchTab = [NSUserDefaults standardUserDefaults].wmf_openAppOnSearchTab;
    if (shouldOpenAppOnSearchTab && self.selectedIndex != WMFAppTabTypeSearch) {
        [self setSelectedIndex:WMFAppTabTypeSearch];
    } else if (self.selectedIndex != WMFAppTabTypeMain) {
        [self setSelectedIndex:WMFAppTabTypeMain];
    }
}

- (void)setupReadingListsHelpers {
    self.readingListsAlertController = [[WMFReadingListsAlertController alloc] init];
    self.readingListHintController = [[WMFReadingListHintController alloc] initWithDataStore:self.dataStore];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidSaveOrUnsaveArticle:) name:WMFReadingListsController.userDidSaveOrUnsaveArticleNotification object:nil];
}

- (void)userDidSaveOrUnsaveArticle:(NSNotification *)note {
    WMFAssertMainThread(@"User save/unsave article notification should only be posted on the main thread");
    id maybeArticle = [note object];
    if (![maybeArticle isKindOfClass:[WMFArticle class]]) {
        return;
    }
    [self showReadingListHintForArticle:(WMFArticle *)maybeArticle];
}

#pragma mark - Notifications

- (void)appWillEnterForegroundWithNotification:(NSNotification *)note {
    // Don't access anything that can't be accessed in the background without starting a background task. For example, don't use anything in the shared app container like all of the Core Data persistent stores
    self.unprocessedUserActivity = nil;
    self.unprocessedShortcutItem = nil;
}

// When the user launches from a terminated state, resume might not finish before didBecomeActive, so these tasks are held until both items complete
- (void)performTasksThatShouldOccurAfterBecomeActiveAndResume {
    [[SessionsFunnel shared] logSessionStart];
    [self checkRemoteAppConfigIfNecessary];
    [self.periodicWorkerController start];
    [self.savedArticlesFetcher start];
    [self.mobileViewToMobileHTMLMigrationController start];
    self.notificationsController.applicationActive = YES;
}

- (void)performTasksThatShouldOccurAfterAnnouncementsUpdated {
    if (self.isResumeComplete) {
        [UserHistoryFunnel.shared logSnapshot];
    }
}

- (void)appDidBecomeActiveWithNotification:(NSNotification *)note {
    // Retry migration if it was terminated by a background task ending
    [self migrateIfNecessary];

    if (![self uiIsLoaded]) {
        return;
    }

    if (self.isResumeComplete) {
        [self performTasksThatShouldOccurAfterBecomeActiveAndResume];
        [UserHistoryFunnel.shared logSnapshot];
    }
}

- (void)appWillResignActiveWithNotification:(NSNotification *)note {
    if (![self uiIsLoaded]) {
        return;
    }
    [self.navigationStateController saveNavigationStateFor:self.navigationController in:self.dataStore.viewContext];
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
        [self pauseApp];
    });
}

- (void)preferredLanguagesDidChange:(NSNotification *)note {
    [self updateExploreFeedPreferencesIfNecessaryForChange:note];
    [self.dataStore.feedContentController updateContentSources];
}

/**
 Updates explore feed preferences if new preferred language was appeneded or removed.
 */
- (void)updateExploreFeedPreferencesIfNecessaryForChange:(NSNotification *)note {
    if (self.isPresentingOnboarding) {
        return;
    }

    NSNumber *changeTypeValue = (NSNumber *)[note userInfo][WMFPreferredLanguagesChangeTypeKey];
    WMFPreferredLanguagesChangeType changeType = (WMFPreferredLanguagesChangeType)changeTypeValue.integerValue;
    if (!changeType || (changeType == WMFPreferredLanguagesChangeTypeReorder)) {
        return;
    }

    MWKLanguageLink *changedLanguage = (MWKLanguageLink *)[note userInfo][WMFPreferredLanguagesLastChangedLanguageKey];
    BOOL appendedNewPreferredLanguage = (changeType == WMFPreferredLanguagesChangeTypeAdd);
    [self.dataStore.feedContentController toggleContentForSiteURL:changedLanguage.siteURL isOn:appendedNewPreferredLanguage waitForCallbackFromCoordinator:NO updateFeed:NO];
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
                                         dismissPreviousAlerts:NO
                                                   tapCallBack:nil];
        }
    }

    if (!error) {
        self.hasSyncErrorBeenShownThisSesssion = NO; // reset on successful sync
        if ([[NSDate date] timeIntervalSinceDate:self.syncStartDate] >= 5) {
            NSInteger syncedReadingListsCount = [note.userInfo[WMFReadingListsController.syncDidFinishSyncedReadingListsCountKey] integerValue];
            NSInteger syncedReadingListEntriesCount = [note.userInfo[WMFReadingListsController.syncDidFinishSyncedReadingListEntriesCountKey] integerValue];
            if (syncedReadingListsCount > 0 && syncedReadingListEntriesCount > 0) {
                NSString *alertTitle = [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"reading-lists-large-sync-completed", nil, nil, @"{{PLURAL:%1$d|%1$d article|%1$d articles}} and {{PLURAL:%2$d|%2$d reading list|%2$d reading lists}} synced from your account", @"Alert message informing user that large sync was completed. %1$d will be replaced with the number of articles which were synced and %2$d will be replaced with the number of reading lists which were synced"), syncedReadingListEntriesCount, syncedReadingListsCount];
                [[WMFAlertManager sharedInstance] showSuccessAlert:alertTitle sticky:YES dismissPreviousAlerts:YES tapCallBack:nil];
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
        dispatch_block_t update = ^{
            [self setSelectedIndex:WMFAppTabTypeSearch];
            [self.navigationController popToRootViewControllerAnimated:NO];
            [self configureTabController];
        };
        if (self.presentedViewController) {
            [self.presentedViewController dismissViewControllerAnimated:YES completion:update];
        } else {
            update();
        }
    });
}

#pragma mark - Hint

- (void)showReadingListHintForArticle:(WMFArticle *)article {
    UIViewController<WMFHintPresenting> *visibleHintPresentingViewController = [self visibleHintPresentingViewController];
    if (!visibleHintPresentingViewController) {
        return;
    }
    [self toggleHint:self.readingListHintController context:@{WMFReadingListHintController.ContextArticleKey: article}];
}

- (void)editWasPublished:(NSNotification *)note {
    if (![NSUserDefaults.standardUserDefaults wmf_didShowFirstEditPublishedPanel]) {
        return;
    }
    [self toggleHint:self.editHintController context:nil];
}

- (void)descriptionEditWasPublished:(NSNotification *)note {
    if (![NSUserDefaults.standardUserDefaults didShowDescriptionPublishedPanel]) {
        return;
    }
    [self toggleHint:self.editHintController context:nil];
}

- (void)talkPageReplyWasPublished:(NSNotification *)note {
    [self toggleHint:self.talkPageReplyHintController context:nil];
}

- (void)talkPageTopicWasPublished:(NSNotification *)note {
    [self toggleHint:self.talkPageTopicHintController context:nil];
}

- (void)referenceLinkTapped:(NSNotification *)note {
    id maybeURL = [note object];
    if (![maybeURL isKindOfClass:[NSURL class]]) {
        return;
    }
    [self wmf_navigateToURL:maybeURL];
}

- (void)toggleHint:(HintController *)hintController context:(nullable NSDictionary<NSString *, id> *)context {
    UIViewController<WMFHintPresenting> *visibleHintPresentingViewController = [self visibleHintPresentingViewController];
    if (!visibleHintPresentingViewController) {
        return;
    }
    [hintController toggleWithPresenter:visibleHintPresentingViewController context:context theme:self.theme];
}

- (UIViewController *)visibleViewController {
    UIViewController *visibleViewController = self.navigationController.visibleViewController;
    if (visibleViewController == self) {
        return self.selectedViewController;
    }
    return visibleViewController;
}

- (UIViewController<WMFHintPresenting> *)visibleHintPresentingViewController {
    UIViewController *visibleViewController = [self visibleViewController];
    if (![visibleViewController conformsToProtocol:@protocol(WMFHintPresenting)]) {
        return nil;
    }
    return (UIViewController<WMFHintPresenting> *)visibleViewController;
}

#pragma mark - Background Fetch

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isMigrationComplete || !self.backgroundFetcherController) {
            completion(UIBackgroundFetchResultNoData);
            return;
        }

        [self.backgroundFetcherController performBackgroundFetch:completion];
    });
}

#pragma mark - Background Tasks

- (UIBackgroundTaskIdentifier)backgroundTaskIdentifierForKey:(NSString *)key {
    if (!key) {
        return UIBackgroundTaskInvalid;
    }
    @synchronized(self.backgroundTasks) {
        NSNumber *identifierNumber = self.backgroundTasks[key];
        if (!identifierNumber) {
            return UIBackgroundTaskInvalid;
        }
        return [identifierNumber unsignedIntegerValue];
    }
}

- (void)setBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)identifier forKey:(NSString *)key {
    if (!key) {
        return;
    }
    @synchronized(self.backgroundTasks) {
        if (identifier == UIBackgroundTaskInvalid) {
            [self.backgroundTasks removeObjectForKey:key];
            return;
        }
        self.backgroundTasks[key] = @(identifier);
    }
}

- (UIBackgroundTaskIdentifier)housekeepingBackgroundTaskIdentifier {
    return [self backgroundTaskIdentifierForKey:@"housekeeping"];
}

- (void)setHousekeepingBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)identifier {
    [self setBackgroundTaskIdentifier:identifier forKey:@"housekeeping"];
}

- (UIBackgroundTaskIdentifier)migrationBackgroundTaskIdentifier {
    return [self backgroundTaskIdentifierForKey:@"migration"];
}

- (void)setMigrationBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)identifier {
    [self setBackgroundTaskIdentifier:identifier forKey:@"migration"];
}

- (UIBackgroundTaskIdentifier)feedContentFetchBackgroundTaskIdentifier {
    return [self backgroundTaskIdentifierForKey:@"feed"];
}

- (void)setFeedContentFetchBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)identifier {
    [self setBackgroundTaskIdentifier:identifier forKey:@"feed"];
}

- (UIBackgroundTaskIdentifier)remoteConfigCheckBackgroundTaskIdentifier {
    return [self backgroundTaskIdentifierForKey:@"remoteConfigCheck"];
}

- (void)setRemoteConfigCheckBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)identifier {
    [self setBackgroundTaskIdentifier:identifier forKey:@"remoteConfigCheck"];
}

- (void)startRemoteConfigCheckBackgroundTask:(dispatch_block_t)expirationHandler {
    if (self.remoteConfigCheckBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        return;
    }
    self.remoteConfigCheckBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (expirationHandler) {
            expirationHandler();
        }
    }];
}

- (void)endRemoteConfigCheckBackgroundTask {
    if (self.remoteConfigCheckBackgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        return;
    }
    UIBackgroundTaskIdentifier backgroundTaskToStop = self.remoteConfigCheckBackgroundTaskIdentifier;
    self.remoteConfigCheckBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskToStop];
}

- (void)startHousekeepingBackgroundTask {
    if (self.housekeepingBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        return;
    }
    self.housekeepingBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
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

    WMFRootNavigationController *articleNavigationController = [[WMFRootNavigationController alloc] initWithRootViewController:self];
    articleNavigationController.themeableNavigationControllerDelegate = self;
    articleNavigationController.delegate = self;
    articleNavigationController.interactivePopGestureRecognizer.delegate = self;
    articleNavigationController.extendedLayoutIncludesOpaqueBars = YES;
    [articleNavigationController setNavigationBarHidden:YES animated:NO];
    [window setRootViewController:articleNavigationController];
    [window makeKeyAndVisible];
    [articleNavigationController applyTheme:self.theme];
    [self updateUserInterfaceStyleOfViewControllerForCurrentTheme:articleNavigationController];

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

    //    TODO: pass the cancellationChecker into performLibraryUpdates to allow it to bail early if the background task is ended
    //    dispatch_block_t bail = ^{
    //        [self endMigrationBackgroundTask];
    //        self.migrationActive = NO;
    //    };
    //    BOOL (^cancellationChecker)() = ^BOOL() {
    //        return migrationsAllowed;
    //    };

    self.migrationActive = YES;

    [self.dataStore
        performLibraryUpdates:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.migrationComplete = YES;
                self.migrationActive = NO;
                [self endMigrationBackgroundTask];
                [self checkRemoteAppConfigIfNecessary];
                [self setupControllers];
                if (!self.isWaitingToResumeApp) {
                    [self resumeApp:NULL];
                }
            });
        }
        needsMigrateBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [(WMFRootNavigationController *)self.navigationController triggerMigratingAnimation];
            });
        }];
}

#pragma mark - Start/Pause/Resume App

- (void)hideSplashScreenAndResumeApp {
    self.waitingToResumeApp = NO;
    if (self.isMigrationComplete) {
        [self resumeApp:NULL];
    }
}

// resumeApp: should be called once and only once for every launch from a fully terminated state.
// It should only be called when the app is active and being shown to the user
- (void)resumeApp:(dispatch_block_t)completion {
    [self presentOnboardingIfNeededWithCompletion:^(BOOL didShowOnboarding) {
        [self loadMainUI];
        dispatch_block_t done = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishResumingApp];
                if (completion) {
                    completion();
                }
            });
        };

        if (self.notificationUserInfoToShow) {
            [self hideSplashViewAnimated:!didShowOnboarding];
            [self showInTheNewsForNotificationInfo:self.notificationUserInfoToShow];
            self.notificationUserInfoToShow = nil;
            done();
        } else if (self.unprocessedUserActivity) {
            [self processUserActivity:self.unprocessedUserActivity
                             animated:NO
                           completion:^{
                               [self hideSplashViewAnimated:!didShowOnboarding];
                               done();
                           }];
        } else if (self.unprocessedShortcutItem) {
            [self hideSplashViewAnimated:!didShowOnboarding];
            [self processShortcutItem:self.unprocessedShortcutItem
                           completion:^(BOOL didProcess) {
                               done();
                           }];
        } else if (NSUserDefaults.standardUserDefaults.shouldRestoreNavigationStackOnResume) {
            [self.navigationStateController restoreNavigationStateFor:self.navigationController
                                                                   in:self.dataStore.viewContext
                                                                 with:self.theme
                                                           completion:^{
                                                               [self hideSplashViewAnimated:!didShowOnboarding];
                                                               done();
                                                           }];
        } else if ([self shouldShowExploreScreenOnLaunch]) {
            [self hideSplashViewAnimated:!didShowOnboarding];
            [self showExplore];
            done();
        } else {
            [self hideSplashViewAnimated:true];
            done();
        }
    }];
}

- (void)finishResumingApp {

    [[WMFDailyStatsLoggingFunnel shared] logAppNumberOfDaysSinceInstall];

    WMFTaskGroup *resumeAndAnnouncementsCompleteGroup = [WMFTaskGroup new];
    [resumeAndAnnouncementsCompleteGroup enter];
    [self.dataStore.authenticationManager
        attemptLoginWithCompletion:^{
            [self checkRemoteAppConfigIfNecessary];
            if (!self.reachabilityNotifier) {
                @weakify(self);
                self.reachabilityNotifier = [[WMFReachabilityNotifier alloc] initWithHost:WMFConfiguration.current.defaultSiteDomain
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
            self.resumeComplete = YES;
            [resumeAndAnnouncementsCompleteGroup leave];
            [self performTasksThatShouldOccurAfterBecomeActiveAndResume];
            [self showLoggedOutPanelIfNeeded];
        }];

    [self.dataStore.feedContentController startContentSources];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *feedRefreshDate = [defaults wmf_feedRefreshDate];
    NSDate *now = [NSDate date];

    BOOL locationAuthorized = [LocationManagerFactory coarseLocationManager].isAuthorized;
    if (!feedRefreshDate || [now timeIntervalSinceDate:feedRefreshDate] > [self timeBeforeRefreshingExploreFeed] || [[NSCalendar wmf_gregorianCalendar] wmf_daysFromDate:feedRefreshDate toDate:now] > 0) {
        [resumeAndAnnouncementsCompleteGroup enter];
        [self.exploreViewController updateFeedSourcesWithDate:nil
                                                userInitiated:NO
                                                   completion:^{
                                                       [resumeAndAnnouncementsCompleteGroup leave];
                                                   }];
    } else {
        if (locationAuthorized != [defaults wmf_locationAuthorized]) {
            [self.dataStore.feedContentController updateContentSource:[WMFNearbyContentSource class] force:NO completion:NULL];
        }
        // TODO: If full navigation stack is not restored (so we're past the cutoff date), should we still force Continue reading card to appear?
        if (!NSUserDefaults.standardUserDefaults.shouldRestoreNavigationStackOnResume) {
            [self.dataStore.feedContentController updateContentSource:[WMFContinueReadingContentSource class] force:YES completion:NULL];
        }

        [resumeAndAnnouncementsCompleteGroup enter];
        [self.dataStore.feedContentController updateContentSource:[WMFAnnouncementsContentSource class]
                                                            force:YES
                                                       completion:^{
                                                           [resumeAndAnnouncementsCompleteGroup leave];
                                                       }];
    }

    [resumeAndAnnouncementsCompleteGroup waitInBackgroundWithCompletion:^{
        [self performTasksThatShouldOccurAfterAnnouncementsUpdated];
    }];

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

    [[NSUserDefaults standardUserDefaults] wmf_setDidShowSyncDisabledPanel:NO];

    self.notificationsController.applicationActive = NO;
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
    [self.houseKeeper performHouseKeepingOnManagedObjectContext:self.dataStore.viewContext navigationStateController:self.navigationStateController error:&housekeepingError];
    if (housekeepingError) {
        DDLogError(@"Error on cleanup: %@", housekeepingError);
        housekeepingError = nil;
    }

    [self endHousekeepingBackgroundTask];
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
        if (self.visibleArticleViewController) {
            [self showSearchInCurrentNavigationController];
        } else {
            [self switchToSearchAnimated:NO];
            [self.searchViewController makeSearchBarBecomeFirstResponder];
        }
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
            return YES;
        case WMFUserActivityTypeSearchResults:
            return [activity wmf_searchTerm] != nil;
        case WMFUserActivityTypeLink:
            return [activity wmf_linkURL] != nil;
        default:
            return NO;
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

    WMFUserActivityType type = [activity wmf_type];

    switch (type) {
        case WMFUserActivityTypeExplore:
            [self dismissPresentedViewControllers];
            [self setSelectedIndex:WMFAppTabTypeMain];
            [self.navigationController popToRootViewControllerAnimated:animated];
            break;
        case WMFUserActivityTypePlaces: {
            [self dismissPresentedViewControllers];
            [self setSelectedIndex:WMFAppTabTypePlaces];
            [self.navigationController popToRootViewControllerAnimated:animated];
            NSURL *articleURL = activity.wmf_linkURL;
            if (articleURL) {
                // For "View on a map" action to succeed, view mode has to be set to map.
                [[self placesViewController] updateViewModeToMap];
                [[self placesViewController] showArticleURL:articleURL];
            }
        } break;
        case WMFUserActivityTypeContent: {
            [self dismissPresentedViewControllers];
            [self setSelectedIndex:WMFAppTabTypeMain];
            UINavigationController *navController = self.navigationController;
            [navController popToRootViewControllerAnimated:animated];
            NSURL *url = [activity wmf_contentURL];
            WMFContentGroup *group = [self.dataStore.viewContext contentGroupForURL:url];
            if (group) {
                switch (group.detailType) {
                    case WMFFeedDisplayTypePhoto: {
                        UIViewController *vc = [group detailViewControllerForPreviewItemAtIndex:0 dataStore:self.dataStore theme:self.theme];
                        [self.navigationController presentViewController:vc animated:false completion:nil];
                    }
                    default: {
                        UIViewController *vc = [group detailViewControllerWithDataStore:self.dataStore theme:self.theme];
                        if (vc) {
                            [navController pushViewController:vc animated:animated];
                        }
                    }
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
            [self dismissPresentedViewControllers];
            [self setSelectedIndex:WMFAppTabTypeSaved];
            [self.navigationController popToRootViewControllerAnimated:animated];
            break;
        case WMFUserActivityTypeHistory:
            [self dismissPresentedViewControllers];
            [self setSelectedIndex:WMFAppTabTypeRecent];
            [self.navigationController popToRootViewControllerAnimated:animated];
            break;
        case WMFUserActivityTypeSearch:
            [self showSearchInCurrentNavigationController];
            break;
        case WMFUserActivityTypeSearchResults:
            [self dismissPresentedViewControllers];
            [self.searchViewController searchAndMakeResultsVisibleForSearchTerm:[activity wmf_searchTerm] animated:animated];
            [self switchToSearchAnimated:animated];
            break;
        case WMFUserActivityTypeSettings:
            [self dismissPresentedViewControllers];
            [self setSelectedIndex:WMFAppTabTypeMain];
            [self.navigationController popToRootViewControllerAnimated:NO];
            [self showSettingsAnimated:animated];
            break;
        case WMFUserActivityTypeAppearanceSettings: {
            [self dismissPresentedViewControllers];
            [self setSelectedIndex:WMFAppTabTypeMain];
            [self.navigationController popToRootViewControllerAnimated:NO];
            WMFAppearanceSettingsViewController *appearanceSettingsVC = [[WMFAppearanceSettingsViewController alloc] init];
            [appearanceSettingsVC applyTheme:self.theme];
            [self showSettingsWithSubViewController:appearanceSettingsVC animated:animated];
        } break;
        default: {
            NSURL *linkURL = [activity wmf_linkURL];
            if (!linkURL) {
                done();
                return NO;
            }
            [NSUserActivity wmf_makeActivityActive:activity];
            return [self.router routeURL:linkURL completion:done];
        }
    }
    done();
    [NSUserActivity wmf_makeActivityActive:activity];
    return YES;
}

#pragma mark - Utilities

- (WMFArticleViewController *)showArticleWithURL:(NSURL *)articleURL animated:(BOOL)animated {
    return [self showArticleWithURL:articleURL
                           animated:animated
                         completion:^{
                         }];
}

- (WMFArticleViewController *)showArticleWithURL:(NSURL *)articleURL animated:(BOOL)animated completion:(nonnull dispatch_block_t)completion {
    if (!articleURL.wmf_title) {
        completion();
        return nil;
    }
    WMFArticleViewController *visibleArticleViewController = self.visibleArticleViewController;
    WMFInMemoryURLKey *visibleKey = visibleArticleViewController.articleURL.wmf_inMemoryKey;
    WMFInMemoryURLKey *articleKey = articleURL.wmf_inMemoryKey;
    if (visibleKey && articleKey && [visibleKey isEqualToInMemoryURLKey:articleKey]) {
        if (articleURL.fragment) {
            [visibleArticleViewController showAnchor:articleURL.fragment];
        }
        completion();
        return visibleArticleViewController;
    }

    UINavigationController *nc = [self currentNavigationController];
    if (!nc) {
        completion();
        return nil;
    }

    if (nc.presentedViewController) {
        [nc dismissViewControllerAnimated:NO completion:NULL];
    }

    WMFArticleViewController *articleVC = [[WMFArticleViewController alloc] initWithArticleURL:articleURL dataStore:self.dataStore theme:self.theme schemeHandler:nil];
    articleVC.loadCompletion = completion;

#if DEBUG
    if ([[[NSProcessInfo processInfo] environment] objectForKey:@"DYLD_PRINT_STATISTICS"]) {
        NSDate *start = [NSDate date];

        articleVC.initialSetupCompletion = ^{
            NSDate *end = [NSDate date];
            NSTimeInterval articleLoadTime = [end timeIntervalSinceDate:start];
            DDLogInfo(@"article load time = %f", articleLoadTime);
        };
    }
#endif

    [nc pushViewController:articleVC
                  animated:YES];
    return articleVC;
}

- (void)swiftCompatibleShowArticleWithURL:(NSURL *)articleURL animated:(BOOL)animated completion:(nonnull dispatch_block_t)completion {
    [self showArticleWithURL:articleURL animated:animated completion:completion];
}

- (BOOL)shouldShowExploreScreenOnLaunch {
    NSDate *resignActiveDate = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeShowingExploreScreenOnLaunch) {
        return YES;
    }
    return NO;
}

- (BOOL)mainViewControllerIsDisplayingContent {
    return self.navigationController.viewControllers.count > 1;
}

- (WMFArticleViewController *)visibleArticleViewController {
    UINavigationController *navVC = self.navigationController;
    UIViewController *topVC = navVC.topViewController;
    if ([topVC isKindOfClass:[WMFArticleViewController class]]) {
        return (WMFArticleViewController *)topVC;
    }
    return nil;
}

- (UIViewController *)viewControllerForTab:(WMFAppTabType)tab {
    return self.viewControllers[tab];
}

#pragma mark - Accessors

- (WMFSavedArticlesFetcher *)savedArticlesFetcher {
    if (![self uiIsLoaded]) {
        return nil;
    }
    if (!_savedArticlesFetcher) {
        _savedArticlesFetcher = [[WMFSavedArticlesFetcher alloc] initWithDataStore:self.dataStore];
        [_savedArticlesFetcher addObserver:self forKeyPath:WMF_SAFE_KEYPATH(_savedArticlesFetcher, progress) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:&kvo_SavedArticlesFetcher_progress];
    }
    return _savedArticlesFetcher;
}

- (WMFMobileViewToMobileHTMLMigrationController *)mobileViewToMobileHTMLMigrationController {
    if (![self uiIsLoaded]) {
        return nil;
    }
    if (!_mobileViewToMobileHTMLMigrationController) {
        _mobileViewToMobileHTMLMigrationController = [[WMFMobileViewToMobileHTMLMigrationController alloc] initWithDataStore:self.dataStore];
    }
    return _mobileViewToMobileHTMLMigrationController;
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
    WMFNotificationsController *controller = self.dataStore.notificationsController;
    controller.applicationActive = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    return controller;
}

- (MWKDataStore *)dataStore {
    return MWKDataStore.shared;
}

- (WMFNavigationStateController *)navigationStateController {
    if (!_navigationStateController) {
        _navigationStateController = [[WMFNavigationStateController alloc] initWithDataStore:self.dataStore];
    }
    return _navigationStateController;
}

- (ExploreViewController *)exploreViewController {
    if (!_exploreViewController) {
        _exploreViewController = [[ExploreViewController alloc] init];
        _exploreViewController.dataStore = self.dataStore;
        _exploreViewController.tabBarItem.image = [UIImage imageNamed:@"tabbar-explore"];
        _exploreViewController.title = [WMFCommonStrings exploreTabTitle];
        [_exploreViewController applyTheme:self.theme];
        UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
        settingsBarButtonItem.accessibilityLabel = [WMFCommonStrings settingsTitle];
        _exploreViewController.navigationItem.rightBarButtonItem = settingsBarButtonItem;
    }
    return _exploreViewController;
}

- (SearchViewController *)searchViewController {
    if (!_searchViewController) {
        _searchViewController = [[SearchViewController alloc] init];
        [_searchViewController applyTheme:self.theme];
        _searchViewController.dataStore = self.dataStore;
        _searchViewController.tabBarItem.image = [UIImage imageNamed:@"search"];
        _searchViewController.title = [WMFCommonStrings searchTitle];
    }
    return _searchViewController;
}

- (WMFSavedViewController *)savedViewController {
    if (!_savedViewController) {
        _savedViewController = [[UIStoryboard storyboardWithName:@"Saved" bundle:nil] instantiateInitialViewController];
        [_savedViewController applyTheme:self.theme];
        _savedViewController.dataStore = self.dataStore;
        _savedViewController.tabBarDelegate = self;
        _savedViewController.tabBarItem.image = [UIImage imageNamed:@"tabbar-save"];
        _savedViewController.title = [WMFCommonStrings savedTabTitle];
    }
    return _savedViewController;
}

- (WMFHistoryViewController *)recentArticlesViewController {
    if (!_recentArticlesViewController) {
        _recentArticlesViewController = [[WMFHistoryViewController alloc] init];
        [_recentArticlesViewController applyTheme:self.theme];
        _recentArticlesViewController.dataStore = self.dataStore;
        _recentArticlesViewController.tabBarItem.image = [UIImage imageNamed:@"tabbar-recent"];
        _recentArticlesViewController.title = [WMFCommonStrings historyTabTitle];
    }
    return _recentArticlesViewController;
}

- (WMFPlacesViewController *)placesViewController {
    if (!_placesViewController) {
        _placesViewController = [[UIStoryboard storyboardWithName:@"Places" bundle:nil] instantiateInitialViewController];
        _placesViewController.dataStore = self.dataStore;
        [_placesViewController applyTheme:self.theme];
        _placesViewController.tabBarItem.image = [UIImage imageNamed:@"tabbar-nearby"];
        _placesViewController.title = [WMFCommonStrings placesTabTitle];
    }
    return _placesViewController;
}

#pragma mark - Onboarding

static NSString *const WMFDidShowOnboarding = @"DidShowOnboarding5.3";

- (BOOL)shouldShowOnboarding {
    NSNumber *didShow = [[NSUserDefaults standardUserDefaults] objectForKey:WMFDidShowOnboarding];
    return !didShow.boolValue;
}

- (void)setDidShowOnboarding {
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:WMFDidShowOnboarding];
}

- (void)presentOnboardingIfNeededWithCompletion:(void (^)(BOOL didShowOnboarding))completion {
    if ([self shouldShowOnboarding]) {
        WMFWelcomeInitialViewController *vc = [WMFWelcomeInitialViewController wmf_viewControllerFromWelcomeStoryboard];
        [vc applyTheme:self.theme];
        vc.completionBlock = ^{
            [self setDidShowOnboarding];
            if (completion) {
                completion(YES);
            }
        };
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentViewController:vc animated:NO completion:NULL];
    } else {
        if (completion) {
            completion(NO);
        }
    }
}

#pragma mark - Splash

- (void)showSplashView {
    [(WMFRootNavigationController *)self.navigationController showSplashView];
}

- (void)hideSplashViewAnimated:(BOOL)animated {
    [(WMFRootNavigationController *)self.navigationController hideSplashViewAnimated:animated];
}

#pragma mark - Explore VC

- (void)showExplore {
    [self setSelectedIndex:WMFAppTabTypeMain];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Last Read Article

- (void)showLastReadArticleAnimated:(BOOL)animated {
    NSURL *lastRead = [self.dataStore.viewContext wmf_openArticleURL];
    [self showArticleWithURL:lastRead animated:animated];
}

#pragma mark - Show Search

- (void)switchToSearchAnimated:(BOOL)animated {
    [self dismissPresentedViewControllers];
    if (self.selectedIndex != WMFAppTabTypeSearch) {
        [self setSelectedIndex:WMFAppTabTypeSearch];
    }
    [self.navigationController popToRootViewControllerAnimated:animated];
}

#pragma mark - App Shortcuts

- (void)dismissPresentedViewControllers {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:NULL];
    }

    if (self.navigationController.presentedViewController) {
        [self.navigationController dismissViewControllerAnimated:NO completion:NULL];
    }
}

- (void)showRandomArticleAnimated:(BOOL)animated {
    [self dismissPresentedViewControllers];
    [self setSelectedIndex:WMFAppTabTypeMain];
    UINavigationController *exploreNavController = self.navigationController;
    WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:[self siteURL] dataStore:self.dataStore theme:self.theme];
    [vc applyTheme:self.theme];
    [exploreNavController pushViewController:vc animated:animated];
}

- (void)showNearbyAnimated:(BOOL)animated {
    [self dismissPresentedViewControllers];
    [self setSelectedIndex:WMFAppTabTypePlaces];
    [self.navigationController popToRootViewControllerAnimated:NO];
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
    BOOL shouldCheckRemoteConfig = now - lastCheckTime >= WMFRemoteAppConfigCheckInterval || self.dataStore.remoteConfigsThatFailedUpdate != 0;
    if (!shouldCheckRemoteConfig) {
        self.checkingRemoteConfig = NO;
        return;
    }
    self.dataStore.isLocalConfigUpdateAllowed = YES;
    [self startRemoteConfigCheckBackgroundTask:^{
        self.dataStore.isLocalConfigUpdateAllowed = NO;
        [self endRemoteConfigCheckBackgroundTask];
    }];
    [self.dataStore updateLocalConfigurationFromRemoteConfigurationWithCompletion:^(NSError *error) {
        if (!error && self.dataStore.isLocalConfigUpdateAllowed) {
            [self.dataStore.viewContext wmf_setValue:[NSNumber numberWithDouble:now] forKey:WMFLastRemoteAppConfigCheckAbsoluteTimeKey];
        }
        self.checkingRemoteConfig = NO;
        [self endRemoteConfigCheckBackgroundTask];
    }];
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
    return YES;
}

- (void)updateActiveTitleAccessibilityButton:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[ExploreViewController class]]) {
        ExploreViewController *vc = (ExploreViewController *)viewController;
        vc.titleButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-title-accessibility-label", nil, nil, @"Wikipedia, scroll to top of Explore", @"Accessibility heading for the Explore page, indicating that tapping it will scroll to the top of the explore page. \"Explore\" is the same as {{msg-wikimedia|Wikipedia-ios-welcome-explore-title}}.");
    } else if ([viewController isKindOfClass:[WMFArticleViewController class]]) {
        WMFArticleViewController *vc = (WMFArticleViewController *)viewController;
        if (self.selectedIndex == WMFAppTabTypeMain) {
            vc.navigationItem.titleView.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-button-explore-accessibility-label", nil, nil, @"Wikipedia, return to Explore", @"Accessibility heading for articles shown within the explore tab, indicating that tapping it will take you back to explore. \"Explore\" is the same as {{msg-wikimedia|Wikipedia-ios-welcome-explore-title}}.");
        } else if (self.selectedIndex == WMFAppTabTypeSaved) {
            vc.navigationItem.titleView.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-button-saved-accessibility-label", nil, nil, @"Wikipedia, return to Saved", @"Accessibility heading for articles shown within the saved articles tab, indicating that tapping it will take you back to the list of saved articles. \"Saved\" is the same as {{msg-wikimedia|Wikipedia-ios-saved-title}}.");
        } else if (self.selectedIndex == WMFAppTabTypeRecent) {
            vc.navigationItem.titleView.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"home-button-history-accessibility-label", nil, nil, @"Wikipedia, return to History", @"Accessibility heading for articles shown within the history articles tab, indicating that tapping it will take you back to the history list. \"History\" is the same as {{msg-wikimedia|Wikipedia-ios-history-title}}.");
        }
    }
}
#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    navigationController.interactivePopGestureRecognizer.delegate = self;
    [self updateActiveTitleAccessibilityButton:viewController];
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    return [self.transitionsController navigationController:navigationController interactionControllerForAnimationController:animationController];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    return [self.transitionsController navigationController:navigationController animationControllerForOperation:operation fromViewController:fromVC toViewController:toVC];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.navigationController.interactivePopGestureRecognizer == gestureRecognizer) {
        return self.navigationController.viewControllers.count > 1;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ![gestureRecognizer isMemberOfClass:[UIScreenEdgePanGestureRecognizer class]];
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
            WMFArticleViewController *articleVC = [self showArticleWithURL:articleURL animated:NO];
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
    WMFFeedNewsStory *feedNewsStory = [MTLJSONAdapter modelOfClass:[WMFFeedNewsStory class] fromJSONDictionary:JSONDictionary languageVariantCode:nil error:&JSONError];
    if (!feedNewsStory || JSONError) {
        DDLogError(@"Error parsing feed news story: %@", JSONError);
        [self showArticleWithURL:articleURL animated:NO];
        return;
    }
    [self dismissPresentedViewControllers];

    if (!feedNewsStory) {
        return;
    }

    UIViewController *vc = [[WMFNewsViewController alloc] initWithStories:@[feedNewsStory] dataStore:self.dataStore contentGroup:nil theme:self.theme];
    if (!vc) {
        return;
    }

    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.navigationController pushViewController:vc animated:NO];
}

#pragma mark - Themeable

- (void)applyTheme:(WMFTheme *)theme toNavigationControllers:(NSArray<UINavigationController *> *)navigationControllers {
    NSMutableSet<UINavigationController *> *foundNavigationControllers = [NSMutableSet setWithCapacity:1];
    for (UINavigationController *nc in navigationControllers) {
        for (UIViewController *vc in nc.viewControllers) {
            if (vc != self && [vc conformsToProtocol:@protocol(WMFThemeable)]) {
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

    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTextColor:theme.colors.primaryText];

    if ([foundNavigationControllers count] > 0) {
        [self applyTheme:theme toNavigationControllers:[foundNavigationControllers allObjects]];
    }
}

- (NSArray<UINavigationController *> *)allNavigationControllers {
    // Navigation controllers
    NSMutableArray<UINavigationController *> *navigationControllers = [NSMutableArray array];
    UINavigationController *navC = self.navigationController;
    if (navC) {
        [navigationControllers addObject:navC];
    }
    if (_settingsNavigationController) {
        [navigationControllers addObject:_settingsNavigationController];
    }
    return navigationControllers;
}

- (void)applyTheme:(WMFTheme *)theme toPresentedViewController:(UIViewController *)viewController {

    if (viewController == nil) {
        return;
    }

    if ([viewController conformsToProtocol:@protocol(WMFThemeable)]) {
        [(id<WMFThemeable>)viewController applyTheme:theme];
    }

    if ([viewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *)viewController.presentedViewController;
        [self applyTheme:theme toNavigationControllers:@[navController]];
    } else {
        [self applyTheme:theme toPresentedViewController:viewController.presentedViewController];
    }
}

- (void)applyTheme:(WMFTheme *)theme {
    if (theme == nil) {
        return;
    }
    self.theme = theme;

    self.view.backgroundColor = theme.colors.baseBackground;
    self.view.tintColor = theme.colors.link;

    [self.settingsViewController applyTheme:theme];
    [self.exploreViewController applyTheme:theme];
    [self.placesViewController applyTheme:theme];
    [self.savedViewController applyTheme:theme];
    [self.recentArticlesViewController applyTheme:theme];
    [self.searchViewController applyTheme:theme];

    [self applyTheme:theme toPresentedViewController:self.presentedViewController];

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

    [self.readingListHintController applyTheme:self.theme];
    [self.editHintController applyTheme:self.theme];

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)updateAppThemeIfNecessary {
    // self.navigationController is the App's root view controller so rely on its trait collection
    WMFTheme *theme = [NSUserDefaults.standardUserDefaults themeCompatibleWith:self.navigationController.traitCollection];
    if (self.theme != theme) {
        [self applyTheme:theme];
        [self.settingsViewController loadSections];
    }
}

- (void)userDidChangeTheme:(NSNotification *)note {
    NSString *themeName = (NSString *)note.userInfo[WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationThemeNameKey];
    NSNumber *isImageDimmingEnabledNumber = (NSNumber *)note.userInfo[WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationIsImageDimmingEnabledKey];
    if (isImageDimmingEnabledNumber) {
        [NSUserDefaults.standardUserDefaults setWmf_isImageDimmingEnabled:isImageDimmingEnabledNumber.boolValue];
    }
    [NSUserDefaults.standardUserDefaults setThemeName:themeName];
    [self updateUserInterfaceStyleOfViewControllerForCurrentTheme:self.navigationController];
    [self updateAppThemeIfNecessary];
}

- (void)updateUserInterfaceStyleOfViewControllerForCurrentTheme:(UIViewController *)viewController {
    if (@available(iOS 13.0, *)) {
        NSString *themeName = [NSUserDefaults.standardUserDefaults themeName];
        if ([WMFTheme isDefaultThemeName:themeName]) {
            viewController.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
        } else if ([WMFTheme isDarkThemeName:themeName]) {
            viewController.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        } else {
            viewController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
    }
}

- (void)debounceTraitCollectionThemeUpdate {
    if (@available(iOS 13.0, *)) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAppThemeIfNecessary) object:nil];
        [self performSelector:@selector(updateAppThemeIfNecessary) withObject:nil afterDelay:0.3];
    }
}

- (void)themeableNavigationControllerTraitCollectionDidChange:(nonnull WMFThemeableNavigationController *)navigationController {
    [self debounceTraitCollectionThemeUpdate];
}

#pragma mark - WMFWorkerControllerDelegate

- (void)workerControllerWillStart:(WMFWorkerController *)workerController workWithIdentifier:(NSString *)identifier {
    NSString *name = [@[NSStringFromClass([workerController class]), identifier] componentsJoinedByString:@"-"];
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:name
                                                                                                     expirationHandler:^{
                                                                                                         DDLogWarn(@"Ending background task with name: %@", name);
                                                                                                         [workerController cancelWorkWithIdentifier:identifier];
                                                                                                     }];
    [self setBackgroundTaskIdentifier:backgroundTaskIdentifier forKey:identifier];
}

- (void)workerControllerDidEnd:(WMFWorkerController *)workerController workWithIdentifier:(NSString *)identifier {
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [self backgroundTaskIdentifierForKey:identifier];
    if (backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        return;
    }
    [UIApplication.sharedApplication endBackgroundTask:backgroundTaskIdentifier];
}

#pragma mark - Article save to disk did fail

- (void)articleSaveToDiskDidFail:(NSNotification *)note {
    NSError *error = (NSError *)note.userInfo[[WMFSavedArticlesFetcher saveToDiskDidFailErrorKey]];
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
    [[NSUserDefaults standardUserDefaults] wmf_setArticleFontSizeMultiplier:multiplier];
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

- (nullable UINavigationController *)currentNavigationController {
    UIViewController *presented = self.presentedViewController;
    while (presented.presentedViewController != nil) {
        presented = presented.presentedViewController;
    }
    if ([presented isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)presented;
    } else {
        return self.navigationController;
    }
}

- (void)showSearchInCurrentNavigationControllerAnimated:(BOOL)animated {
    NSParameterAssert(self.dataStore);

    [self dismissReadingThemesPopoverIfActive];

    UINavigationController *nc = self.currentNavigationController;
    if (!nc) {
        return;
    }

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
        searchVC.areRecentSearchesEnabled = YES;
        [searchVC applyTheme:self.theme];
        searchVC.dataStore = self.dataStore;
    }

    [nc pushViewController:searchVC animated:true];
}

- (nonnull WMFSettingsViewController *)settingsViewController {
    if (!_settingsViewController) {
        WMFSettingsViewController *settingsVC =
            [WMFSettingsViewController settingsViewControllerWithDataStore:self.dataStore];
        [settingsVC applyTheme:self.theme];
        _settingsViewController = settingsVC;
        _settingsViewController.tabBarItem.image = [UIImage imageNamed:@"tabbar-explore"];
    }
    return _settingsViewController;
}

- (nonnull UINavigationController *)settingsNavigationController {
    if (!_settingsNavigationController) {
        WMFThemeableNavigationController *navController = [[WMFThemeableNavigationController alloc] initWithRootViewController:self.settingsViewController theme:self.theme];
        [self applyTheme:self.theme toNavigationControllers:@[navController]];
        _settingsNavigationController = navController;
        _settingsNavigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }

    if (_settingsNavigationController.viewControllers.firstObject != self.settingsViewController) {
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

    switch ([NSUserDefaults standardUserDefaults].defaultTabType) {
        case WMFAppDefaultTabTypeSettings:
            [self setSelectedIndex:WMFAppTabTypeMain];
            if (subViewController) {
                [self wmf_pushViewController:subViewController animated:animated];
            }
            break;
        default:
            [self presentViewController:self.settingsNavigationController animated:animated completion:nil];
            break;
    }
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
    [self showArticleWithURL:articleURL animated:YES];
}

#pragma mark - User was logged out

- (void)userWasLoggedOut:(NSNotification *)note {
    [self showLoggedOutPanelIfNeeded];
}

- (void)showLoggedOutPanelIfNeeded {
    WMFAuthenticationManager *authenticationManager = self.dataStore.authenticationManager;
    BOOL isUserUnawareOfLogout = authenticationManager.isUserUnawareOfLogout;
    if (!isUserUnawareOfLogout) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self wmf_showLoggedOutPanelWithTheme:self.theme
                               dismissHandler:^{
                                   [authenticationManager userDidAcknowledgeUnintentionalLogout];
                               }];
    });
}

@end
