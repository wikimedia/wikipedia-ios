#import "WMFSettingsTableViewCell.h"
@import WMF;
#import "Wikipedia-Swift.h"

#import "WMFSettingsViewController.h"
#import "WMFLanguagesViewController.h"
#import "AboutViewController.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFDailyStatsLoggingFunnel.h"

#pragma mark - Static URLs

static const NSString *kvo_WMFSettingsViewController_authManager_loggedInUsername = nil;

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFSettingsURLZeroFAQ = @"https://foundation.m.wikimedia.org/wiki/Wikipedia_Zero_App_FAQ";
static NSString *const WMFSettingsURLTerms = @"https://foundation.m.wikimedia.org/wiki/Terms_of_Use/en";
static NSString *const WMFSettingsURLRate = @"itms-apps://itunes.apple.com/app/id324715238";
static NSString *const WMFSettingsURLDonation = @"https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=<app-version>&uselang=<langcode>";

@interface WMFSettingsViewController () <UITableViewDelegate, UITableViewDataSource, WMFPreferredLanguagesViewControllerDelegate, WMFAccountViewControllerDelegate>

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

    self.authManager = self.dataStore.authenticationManager;

    self.navigationBar.displayType = NavigationBarDisplayTypeLargeTitle;
#if UI_TEST
    if ([[NSUserDefaults standardUserDefaults] wmf_isFastlaneSnapshotInProgress]) {
        self.tableView.decelerationRate = UIScrollViewDecelerationRateFast;
    }
#endif
}

- (void)dealloc {
    self.authManager = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setAuthManager:(nullable WMFAuthenticationManager *)authManager {
    if (_authManager == authManager) {
        return;
    }

    NSString *keyPath = WMF_SAFE_KEYPATH(authManager, loggedInUsername);

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

    /// Terrible hack to make back button text appropriate for iOS 14 - need to set the title on `WMFAppViewController`. For all app tabs, this is set in `viewWillAppear`.
    self.parentViewController.navigationItem.backButtonTitle = self.title;
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

- (BOOL)accessibilityPerformEscape {
    [self closeButtonPressed];
    return YES;
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
            WMFEventPlatformClient *eventPlatformClient = [WMFEventPlatformClient sharedInstance];
            NSUserDefaults.standardUserDefaults.wmf_sendUsageReports = isOn;
            if (isOn) {
                [eventLoggingService reset];
                [eventPlatformClient reset];
                [[WMFDailyStatsLoggingFunnel shared] logAppNumberOfDaysSinceInstall];
                [[SessionsFunnel shared] logSessionStart];
                [[UserHistoryFunnel shared] logStartingSnapshot];
            } else {
                [[SessionsFunnel shared] logSessionEnd];
                [[UserHistoryFunnel shared] logSnapshot];
                [eventLoggingService reset];
                [eventPlatformClient reset];
            }
        } break;
        default:
            break;
    }
}

#pragma mark - Cell tap handling

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    switch (cell.tag) {
        case WMFSettingsMenuItemType_LoginAccount:
            [self showLoginOrAccount];
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
            [self wmf_navigateToURL:[self donationURL] useSafari:YES];
            break;
        case WMFSettingsMenuItemType_PrivacyPolicy:
            [self wmf_navigateToURL:[NSURL URLWithString:[WMFCommonStrings privacyPolicyURLString]]];
            break;
        case WMFSettingsMenuItemType_Terms:
            [self wmf_navigateToURL:[NSURL URLWithString:WMFSettingsURLTerms]];
            break;
        case WMFSettingsMenuItemType_ZeroFAQ:
            [self wmf_navigateToURL:[NSURL URLWithString:WMFSettingsURLZeroFAQ]];
            break;
        case WMFSettingsMenuItemType_RateApp:
            [self wmf_navigateToURL:[NSURL URLWithString:WMFSettingsURLRate] useSafari:YES];
            break;
        case WMFSettingsMenuItemType_SendFeedback: {
            WMFHelpViewController *vc = [[WMFHelpViewController alloc] initWithDataStore:self.dataStore theme:self.theme];
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
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Dynamic URLs

- (NSURL *)donationURL {
    NSString *url = WMFSettingsURLDonation;

    NSString *languageCode = MWKDataStore.shared.languageLinkController.appLanguage.languageCode;
    languageCode = [languageCode stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSString *appVersion = [[NSBundle mainBundle] wmf_debugVersion];
    appVersion = [appVersion stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    url = [url stringByReplacingOccurrencesOfString:@"<langcode>" withString:languageCode];
    url = [url stringByReplacingOccurrencesOfString:@"<app-version>" withString:appVersion];

    return [NSURL URLWithString:url];
}

#pragma mark - Presentation

- (void)presentViewControllerWrappedInNavigationController:(UIViewController<WMFThemeable> *)viewController {
    WMFThemeableNavigationController *themeableNavController = [[WMFThemeableNavigationController alloc] initWithRootViewController:viewController theme:self.theme style:WMFThemeableNavigationControllerStyleSheet];
    [self presentViewController:themeableNavController animated:YES completion:nil];
}

#pragma mark - Log in and out

- (void)showLoginOrAccount {
    NSString *userName = self.dataStore.authenticationManager.loggedInUsername;
    if (userName) {
        WMFAccountViewController *accountVC = [[WMFAccountViewController alloc] init];
        accountVC.dataStore = self.dataStore;
        accountVC.delegate = self;
        [accountVC applyTheme:self.theme];
        [self.navigationController pushViewController:accountVC animated:YES];
    } else {
        WMFLoginViewController *loginVC = [WMFLoginViewController wmf_initialViewControllerFromClassStoryboard];
        [loginVC applyTheme:self.theme];
        [self presentViewControllerWrappedInNavigationController:loginVC];
        [[LoginFunnel shared] logLoginStartInSettings];
    }
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
                                                [self.dataStore clearTemporaryCache];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-cancel", nil, nil, @"Cancel", @"Cancel action to clear cached data {{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];

    [self presentViewController:sheet animated:YES completion:NULL];
}

- (void)logout {
    [self wmf_showKeepSavedArticlesOnDevicePanelIfNeededTriggeredBy:KeepSavedArticlesTriggerLogout
                                                                     theme:self.theme
                                                                completion:^{
                                                                    [self.dataStore.authenticationManager logoutInitiatedBy:LogoutInitiatorUser completion:^{
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
        [[NSUserDefaults standardUserDefaults] wmf_setShowSearchLanguageBar:YES];
    } else {
        [[NSUserDefaults standardUserDefaults] wmf_setShowSearchLanguageBar:NO];
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
    [self.tableView reloadData];
}

#pragma mark - Section structure

- (WMFSettingsTableViewSection *)section_1 {
    NSArray *items = @[[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_LoginAccount],
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
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_RateApp],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendFeedback],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_About]
    ]
                                                                                  headerTitle:nil
                                                                                   footerText:nil];
    return section;
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadSections];
        });
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

#pragma Mark WMFAccountViewControllerDelegate

- (void)accountViewControllerDidTapLogout:(WMFAccountViewController * _Nonnull)accountViewController {
    [self logout];
    [self loadSections];
}

@end

NS_ASSUME_NONNULL_END
