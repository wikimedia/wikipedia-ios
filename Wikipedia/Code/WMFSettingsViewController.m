#import "WMFSettingsTableViewCell.h"
#import "Wikipedia-Swift.h"
#import <WMF/NSUserActivity+WMFExtensions.h>

// View Controllers
#import "WMFSettingsViewController.h"
#import "WMFLanguagesViewController.h"
#import "AboutViewController.h"
#import "WMFHelpViewController.h"

// Models
#import <WMF/MWKLanguageLink.h>

// Frameworks
#import <HockeySDK/HockeySDK.h>
#if WMF_TWEAKS_ENABLED
#import <Tweaks/FBTweakViewController.h>
#import <Tweaks/FBTweakStore.h>
#endif

// Other
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import <WMF/UIView+WMFDefaultNib.h>
#import <WMF/SessionSingleton.h>
#import "UIViewController+WMFStoryboardUtilities.h"
#import <WMF/MWKLanguageLinkController.h>
#import "UIViewController+WMFOpenExternalUrl.h"
#import "WMFDailyStatsLoggingFunnel.h"
#import <WMF/NSBundle+WMFInfoUtils.h>
#import "Wikipedia-Swift.h"

#pragma mark - Static URLs

static const NSString *kvo_WMFSettingsViewController_authManager_loggedInUsername = nil;

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFSettingsURLZeroFAQ = @"https://foundation.m.wikimedia.org/wiki/Wikipedia_Zero_App_FAQ";
static NSString *const WMFSettingsURLTerms = @"https://foundation.m.wikimedia.org/wiki/Terms_of_Use/en";
static NSString *const WMFSettingsURLRate = @"itms-apps://itunes.apple.com/app/id324715238";
static NSString *const WMFSettingsURLDonation = @"https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=<app-version>&uselang=<langcode>";

#if WMF_TWEAKS_ENABLED
@interface WMFSettingsViewController () <UITableViewDelegate, UITableViewDataSource, WMFPreferredLanguagesViewControllerDelegate, FBTweakViewControllerDelegate>
#else
@interface WMFSettingsViewController () <UITableViewDelegate, UITableViewDataSource, WMFPreferredLanguagesViewControllerDelegate>
#endif

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;

@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nullable, nonatomic) WMFAuthenticationManager *authManager;

@end

@implementation WMFSettingsViewController

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store {
    NSParameterAssert(store);
    WMFSettingsViewController *vc = [WMFSettingsViewController wmf_initialViewControllerFromClassStoryboard];
    vc.dataStore = store;
    return vc;
}

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    [self.tableView registerNib:[WMFSettingsTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFSettingsTableViewCell identifier]];

    self.tableView.estimatedRowHeight = 52.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.authManager = [WMFAuthenticationManager sharedInstance];

    self.navigationBar.displayType = NavigationBarDisplayTypeLargeTitle;
}

- (void)dealloc {
    self.authManager = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setAuthManager:(nullable WMFAuthenticationManager *)authManager {
    if (_authManager == authManager) {
        return;
    }

    NSString *keyPath = WMF_SAFE_KEYPATH([WMFAuthenticationManager sharedInstance], loggedInUsername);

    [_authManager removeObserver:self forKeyPath:keyPath context:&kvo_WMFSettingsViewController_authManager_loggedInUsername];
    _authManager = authManager;
    [_authManager addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_WMFSettingsViewController_authManager_loggedInUsername];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_settingsViewActivity]];
}

- (UIScrollView *_Nullable)scrollView {
    return self.tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    self.showCloseButton = self.tabBarController == nil;
    [self.navigationController setNavigationBarHidden:YES];
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
    [self loadSections];
}

- (void)configureBackButton {
    if (self.navigationItem.rightBarButtonItem != nil) {
        return;
    }
    UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(closeButtonPressed)];
    self.navigationItem.rightBarButtonItem = xButton;
}

- (void)setShowCloseButton:(BOOL)showCloseButton {
    if (showCloseButton) {
        [self configureBackButton];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)closeButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (nullable NSString *)title {
    return [WMFCommonStrings settingsTitle];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WMFSettingsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:WMFSettingsTableViewCell.identifier forIndexPath:indexPath];

    NSArray *menuItems = [self.sections[indexPath.section] getItems];
    WMFSettingsMenuItem *menuItem = menuItems[indexPath.item];

    cell.tag = menuItem.type;
    cell.title = menuItem.title;
    [cell applyTheme:self.theme];
    if (!self.theme.colors.icon) {
        cell.iconColor = [UIColor whiteColor];
        cell.iconBackgroundColor = menuItem.iconColor;
    }
    cell.iconName = menuItem.iconName;
    cell.disclosureType = menuItem.disclosureType;
    cell.disclosureText = menuItem.disclosureText;
    [cell.disclosureSwitch setOn:menuItem.isSwitchOn];
    cell.selectionStyle = (menuItem.disclosureType == WMFSettingsMenuItemDisclosureType_Switch) ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

    if (menuItem.disclosureType != WMFSettingsMenuItemDisclosureType_Switch && menuItem.disclosureType != WMFSettingsMenuItemDisclosureType_None) {
        cell.accessibilityTraits = UIAccessibilityTraitButton;
    } else {
        cell.accessibilityTraits = UIAccessibilityTraitStaticText;
    }

    [cell.disclosureSwitch removeTarget:self action:@selector(disclosureSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.disclosureSwitch.tag = menuItem.type;
    [cell.disclosureSwitch addTarget:self action:@selector(disclosureSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    return cell;
}

- (void)disclosureSwitchChanged:(UISwitch *)disclosureSwitch {
    WMFSettingsMenuItemType type = (WMFSettingsMenuItemType)disclosureSwitch.tag;
    [self updateStateForMenuItemType:type isSwitchOnValue:disclosureSwitch.isOn];
    [self loadSections];
}

#pragma mark - Switch tap handling

- (void)updateStateForMenuItemType:(WMFSettingsMenuItemType)type isSwitchOnValue:(BOOL)isOn {
    switch (type) {
        case WMFSettingsMenuItemType_SendUsageReports: {
            WMFEventLoggingService *eventLoggingService = [WMFEventLoggingService sharedInstance];
            eventLoggingService.isEnabled = isOn;
            if (isOn) {
                [eventLoggingService reset];
                [[WMFDailyStatsLoggingFunnel shared] logAppNumberOfDaysSinceInstall];
                [[SessionsFunnel shared] logSessionStart];
                [[UserHistoryFunnel shared] logStartingSnapshot];
            } else {
                [[SessionsFunnel shared] logSessionEnd];
                [[UserHistoryFunnel shared] logSnapshot];
                [eventLoggingService reset];
            }
            [[WMFSession shared] setShouldSendUsageReports:isOn];
            [[QueuesSingleton sharedInstance] reset];
        } break;
        case WMFSettingsMenuItemType_ZeroWarnWhenLeaving:
            [SessionSingleton sharedInstance].zeroConfigurationManager.warnWhenLeaving = isOn;
            break;
        default:
            break;
    }
}

#pragma mark - Cell tap handling

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    switch (cell.tag) {
        case WMFSettingsMenuItemType_Login:
            [self showLoginOrLogout];
            break;
        case WMFSettingsMenuItemType_SearchLanguage:
            [self showLanguages];
            break;
        case WMFSettingsMenuItemType_Search:
            [self showSearch];
            break;
        case WMFSettingsMenuItemType_ExploreFeed:
            [self showExploreFeedSettings];
            break;
        case WMFSettingsMenuItemType_Notifications:
            [self showNotifications];
            break;
        case WMFSettingsMenuItemType_Appearance: {
            [self showAppearance];
            break;
        }
        case WMFSettingsMenuItemType_StorageAndSyncing: {
            [self showStorageAndSyncing];
            break;
        }
        case WMFSettingsMenuItemType_StorageAndSyncingDebug: {
            [self showStorageAndSyncingDebug];
            break;
        }
        case WMFSettingsMenuItemType_Support:
            [self wmf_openExternalUrl:[self donationURL] useSafari:YES];
            break;
        case WMFSettingsMenuItemType_PrivacyPolicy:
            [self wmf_openExternalUrl:[NSURL URLWithString:[WMFCommonStrings privacyPolicyURLString]]];
            break;
        case WMFSettingsMenuItemType_Terms:
            [self wmf_openExternalUrl:[NSURL URLWithString:WMFSettingsURLTerms]];
            break;
        case WMFSettingsMenuItemType_ZeroFAQ:
            [self wmf_openExternalUrl:[NSURL URLWithString:WMFSettingsURLZeroFAQ]];
            break;
        case WMFSettingsMenuItemType_RateApp:
            [self wmf_openExternalUrl:[NSURL URLWithString:WMFSettingsURLRate] useSafari:YES];
            break;
        case WMFSettingsMenuItemType_SendFeedback: {
            WMFHelpViewController *vc = [[WMFHelpViewController alloc] initWithDataStore:self.dataStore];
            [vc applyTheme:self.theme];
            [self.navigationController pushViewController:vc animated:YES];
        } break;
        case WMFSettingsMenuItemType_About: {
            AboutViewController *vc = [[AboutViewController alloc] initWithTheme:self.theme];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case WMFSettingsMenuItemType_ClearCache:
            [self showClearCacheActionSheet];
            break;
        case WMFSettingsMenuItemType_DebugCrash:
            [[self class] generateTestCrash];
            break;
        case WMFSettingsMenuItemType_DevSettings: {
#if WMF_TWEAKS_ENABLED
            FBTweakViewController *tweaksVC = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance]];
            tweaksVC.tweaksDelegate = self;
            [self presentViewController:tweaksVC animated:YES completion:nil];
#endif
        }
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#if WMF_TWEAKS_ENABLED
- (void)motionEnded:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        DebugReadingListsViewController *vc = [[DebugReadingListsViewController alloc] initWithNibName:@"DebugReadingListsViewController" bundle:nil];
        [self presentViewControllerWrappedInNavigationController:vc];
    }
}
#endif

#pragma mark - Dynamic URLs

- (NSURL *)donationURL {
    NSString *url = WMFSettingsURLDonation;

    NSString *languageCode = [[MWKLanguageLinkController sharedInstance] appLanguage].languageCode;
    languageCode = [languageCode stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSString *appVersion = [[NSBundle mainBundle] wmf_debugVersion];
    appVersion = [appVersion stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    url = [url stringByReplacingOccurrencesOfString:@"<langcode>" withString:languageCode];
    url = [url stringByReplacingOccurrencesOfString:@"<app-version>" withString:appVersion];

    return [NSURL URLWithString:url];
}

#pragma mark - Presentation

- (void)presentViewControllerWrappedInNavigationController:(UIViewController<WMFThemeable> *)viewController {
    WMFThemeableNavigationController *themeableNavController = [[WMFThemeableNavigationController alloc] initWithRootViewController:viewController theme:self.theme];
    [self presentViewController:themeableNavController animated:YES completion:nil];
}

#pragma mark - Log in and out

- (void)showLoginOrLogout {
    NSString *userName = [WMFAuthenticationManager sharedInstance].loggedInUsername;
    if (userName) {
        [self showLogoutActionSheet];
    } else {
        WMFLoginViewController *loginVC = [WMFLoginViewController wmf_initialViewControllerFromClassStoryboard];
        [loginVC applyTheme:self.theme];
        [self presentViewControllerWrappedInNavigationController:loginVC];
        [[LoginFunnel shared] logLoginStartInSettings];
    }
}

- (void)showLogoutActionSheet {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:WMFLocalizedStringWithDefaultValue(@"main-menu-account-logout-are-you-sure", nil, nil, @"Are you sure you want to log out?", @"Header asking if user is sure they wish to log out.") message:nil preferredStyle:UIAlertControllerStyleAlert];
    @weakify(self)
        [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"main-menu-account-logout", nil, nil, @"Log out", @"Button text for logging out. The username of the user who is currently logged in is displayed after the message, e.g. Log out ExampleUserName.\n{{Identical|Log out}}")
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *_Nonnull action) {
                                                    @strongify(self)
                                                        [self logout];
                                                    [self loadSections];
                                                }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"main-menu-account-logout-cancel", nil, nil, @"Cancel", @"Button text for hiding the log out menu.\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];

    [self presentViewController:sheet animated:YES completion:NULL];
}

#pragma mark - Clear Cache

- (void)showClearCacheActionSheet {
    NSString *message = WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-are-you-sure-message", nil, nil, @"Clearing cached data will free up about %1$@ of space. It will not delete your saved pages.", @"Message for the confirmation presented to the user to verify they are sure they want to clear clear cached data. %1$@ is replaced with the approximate file size in bytes that will be made available. Also explains that the action will not delete their saved pages.");
    NSString *bytesString = [NSByteCountFormatter stringFromByteCount:[NSURLCache sharedURLCache].currentDiskUsage countStyle:NSByteCountFormatterCountStyleFile];
    message = [NSString localizedStringWithFormat:message, bytesString];

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-are-you-sure-title", nil, nil, @"Clear cached data?", @"Title for the confirmation presented to the user to verify they are sure they want to clear clear cached data.") message:message preferredStyle:UIAlertControllerStyleAlert];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-ok", nil, nil, @"Clear cache", @"Confirm action to clear cached data")
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [self.dataStore clearCachesForUnsavedArticles];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-cancel", nil, nil, @"Cancel", @"Cancel action to clear cached data\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];

    [self presentViewController:sheet animated:YES completion:NULL];
}

- (void)logout {
    [self wmf_showKeepSavedArticlesOnDevicePanelIfNecessaryWithTriggeredBy:KeepSavedArticlesTriggerLogout
                                                                     theme:self.theme
                                                                completion:^{
                                                                    [[WMFAuthenticationManager sharedInstance] logoutWithCompletion:^{
                                                                        [[LoginFunnel shared] logLogoutInSettings];
                                                                    }];
                                                                }];
}

#pragma mark - Languages

- (void)showLanguages {
    WMFPreferredLanguagesViewController *languagesVC = [WMFPreferredLanguagesViewController preferredLanguagesViewController];
    languagesVC.showExploreFeedCustomizationSettings = YES;
    languagesVC.delegate = self;
    [languagesVC applyTheme:self.theme];
    [self presentViewControllerWrappedInNavigationController:languagesVC];
}

- (void)languagesController:(WMFPreferredLanguagesViewController *)controller didUpdatePreferredLanguages:(NSArray<MWKLanguageLink *> *)languages {
    if ([languages count] > 1) {
        [[NSUserDefaults wmf] wmf_setShowSearchLanguageBar:YES];
    } else {
        [[NSUserDefaults wmf] wmf_setShowSearchLanguageBar:NO];
    }

    [self loadSections];
}

#pragma mark - Search

- (void)showSearch {
    WMFSearchSettingsViewController *searchSettingsViewController = [[WMFSearchSettingsViewController alloc] init];
    [searchSettingsViewController applyTheme:self.theme];
    [self.navigationController pushViewController:searchSettingsViewController animated:YES];
}

#pragma mark - Feed

- (void)showExploreFeedSettings {
    WMFExploreFeedSettingsViewController *feedSettingsVC = [[WMFExploreFeedSettingsViewController alloc] init];
    feedSettingsVC.dataStore = self.dataStore;
    [feedSettingsVC applyTheme:self.theme];
    [self.navigationController pushViewController:feedSettingsVC animated:YES];
}

#pragma mark - Notifications

- (void)showNotifications {
    WMFNotificationSettingsViewController *notificationSettingsVC = [[WMFNotificationSettingsViewController alloc] init];
    [notificationSettingsVC applyTheme:self.theme];
    [self.navigationController pushViewController:notificationSettingsVC animated:YES];
}

#pragma mark - Appearance

- (void)showAppearance {
    WMFAppearanceSettingsViewController *appearanceSettingsVC = [[WMFAppearanceSettingsViewController alloc] init];
    [appearanceSettingsVC applyTheme:self.theme];
    [self.navigationController pushViewController:appearanceSettingsVC animated:YES];
}

#pragma mark - Storage and syncing

- (void)showStorageAndSyncing {
    WMFStorageAndSyncingSettingsViewController *storageAndSyncingSettingsVC = [[WMFStorageAndSyncingSettingsViewController alloc] init];
    storageAndSyncingSettingsVC.dataStore = self.dataStore;
    [storageAndSyncingSettingsVC applyTheme:self.theme];
    [self.navigationController pushViewController:storageAndSyncingSettingsVC animated:YES];
}

- (void)showStorageAndSyncingDebug {
#if DEBUG
    DebugReadingListsViewController *vc = [[DebugReadingListsViewController alloc] initWithNibName:@"DebugReadingListsViewController" bundle:nil];
    [self presentViewControllerWrappedInNavigationController:vc];
#endif
}

#pragma mark - Debugging

+ (void)generateTestCrash {
    if ([[BITHockeyManager sharedHockeyManager] crashManager]) {
        DDLogWarn(@"Generating test crash!");
        __builtin_trap();
    } else {
        DDLogError(@"Crash manager was not setup!");
    }
}

#if WMF_TWEAKS_ENABLED
- (void)tweakViewControllerPressedDone:(FBTweakViewController *)tweakViewController {
    [[NSNotificationCenter defaultCenter] postNotificationName:FBTweakShakeViewControllerDidDismissNotification object:tweakViewController];
    [tweakViewController dismissViewControllerAnimated:YES completion:nil];
}
#endif

#pragma mark - Cell reloading

- (nullable NSIndexPath *)indexPathForVisibleCellOfType:(WMFSettingsMenuItemType)type {
    return [self.tableView.indexPathsForVisibleRows wmf_match:^BOOL(NSIndexPath *indexPath) {
        return ([self.tableView cellForRowAtIndexPath:indexPath].tag == type);
    }];
}

#pragma mark - Sections structure

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    NSArray *items = [self.sections[section] getItems];
    return items.count;
}

- (nullable NSString *)tableView:(UITableView *)tableView
         titleForHeaderInSection:(NSInteger)section {
    NSString *header = [self.sections[section] getHeaderTitle];
    if (header != nil) {
        return header;
    }
    return nil;
}

- (void)loadSections {
    self.sections = [[NSMutableArray alloc] init];

    [self.sections addObject:[self section_1]];
    [self.sections addObject:[self section_2]];
    [self.sections addObject:[self section_3]];
    [self.sections addObject:[self section_4]];
    [self.sections addObject:[self section_5]];
    WMFSettingsTableViewSection *section6 = [self section_6];
    if (section6) {
        [self.sections addObject:section6];
    }

    [self.tableView reloadData];
}

#pragma mark - Section structure

- (WMFSettingsTableViewSection *)section_1 {
    NSArray *items = @[[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Login],
                       [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Support]];
    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:items
                                                                                  headerTitle:nil
                                                                                   footerText:nil];
    return section;
}

- (WMFSettingsTableViewSection *)section_2 {
    NSArray *commonItems = @[[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SearchLanguage],
                             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Search]];
    NSMutableArray *items = [NSMutableArray arrayWithArray:commonItems];
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ExploreFeed]];

    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Notifications]];

    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Appearance]];
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_StorageAndSyncing]];
#if DEBUG
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_StorageAndSyncingDebug]];
#endif
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ClearCache]];
    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:items headerTitle:nil footerText:nil];
    return section;
}

- (WMFSettingsTableViewSection *)section_3 {
    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:@[
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_PrivacyPolicy],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Terms],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendUsageReports]
    ]
                                                                                  headerTitle:WMFLocalizedStringWithDefaultValue(@"main-menu-heading-legal", nil, nil, @"Privacy and Terms", @"Header text for the legal section of the menu. Consider using something informal, but feel free to use a more literal translation of \"Legal info\" if it seems more appropriate.")
                                                                                   footerText:WMFLocalizedStringWithDefaultValue(@"preference-summary-eventlogging-opt-in", nil, nil, @"Allow Wikimedia Foundation to collect information about how you use the app to make the app better", @"Description of preference that when checked enables data collection of user behavior.")];

    return section;
}

- (WMFSettingsTableViewSection *)section_4 {
    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:@[
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ZeroWarnWhenLeaving],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ZeroFAQ]
    ]
                                                                                  headerTitle:WMFLocalizedStringWithDefaultValue(@"main-menu-heading-zero", nil, nil, @"Wikipedia Zero", @"Header text for the Wikipedia Zero section of the menu. ([https://foundation.wikimedia.org/wiki/Wikipedia_Zero More information]).\n{{Identical|Wikipedia Zero}}")
                                                                                   footerText:nil];
    return section;
}

- (WMFSettingsTableViewSection *)section_5 {
    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:@[
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_RateApp],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendFeedback],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_About]
    ]
                                                                                  headerTitle:nil
                                                                                   footerText:nil];
    return section;
}

- (nullable WMFSettingsTableViewSection *)section_6 {
#if WMF_TWEAKS_ENABLED
    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:@[
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_DebugCrash],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_DevSettings]
    ]
                                                                                  headerTitle:WMFLocalizedStringWithDefaultValue(@"main-menu-heading-debug", nil, nil, @"Debug", @"Header text for the debug section of the menu. The debug menu is conditionally shown if in Xcode debug mode.\n{{Identical|Debug}}")
                                                                                   footerText:nil];
    return section;
#else
    return nil;
#endif
}

#pragma mark - Scroll view

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self.navigationBarHider scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidEndScrollingAnimation:scrollView];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewWillScrollToTop:scrollView];
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidScrollToTop:scrollView];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    if (context == &kvo_WMFSettingsViewController_authManager_loggedInUsername) {
        [self loadSections];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    [super applyTheme:theme];
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.tableView.backgroundColor = theme.colors.baseBackground;
    self.tableView.indicatorStyle = theme.scrollIndicatorStyle;
    self.view.backgroundColor = theme.colors.baseBackground;
    [self loadSections];
}

@end

NS_ASSUME_NONNULL_END
