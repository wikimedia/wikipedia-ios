#import "WMFSettingsTableViewCell.h"
#import "Wikipedia-Swift.h"
#import "NSUserActivity+WMFExtensions.h"

// View Controllers
#import "WMFSettingsViewController.h"
#import "WMFLanguagesViewController.h"
#import "AboutViewController.h"
#import "WMFHelpViewController.h"

// Models
#import "MWKLanguageLink.h"

// Frameworks
#import <HockeySDK/HockeySDK.h>
#if WMF_TWEAKS_ENABLED
#import <Tweaks/FBTweakViewController.h>
#import <Tweaks/FBTweakStore.h>
#endif
#import "SSDataSources.h"

// Other
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIView+WMFDefaultNib.h"
#import "SessionSingleton.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "MWKLanguageLinkController.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "NSBundle+WMFInfoUtils.h"
#import "Wikipedia-Swift.h"

#pragma mark - Static URLs

static const NSString *kvo_WMFSettingsViewController_authManager_loggedInUsername = nil;

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFSettingsURLZeroFAQ = @"https://m.wikimediafoundation.org/wiki/Wikipedia_Zero_App_FAQ";
static NSString *const WMFSettingsURLTerms = @"https://m.wikimediafoundation.org/wiki/Terms_of_Use";
static NSString *const WMFSettingsURLRate = @"itms-apps://itunes.apple.com/app/id324715238";
static NSString *const WMFSettingsURLDonation = @"https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=<app-version>&uselang=<langcode>";
static NSString *const WMFSettingsURLPrivacyPolicy = @"https://m.wikimediafoundation.org/wiki/Privacy_policy";

#if WMF_TWEAKS_ENABLED
@interface WMFSettingsViewController () <UITableViewDelegate, WMFPreferredLanguagesViewControllerDelegate, FBTweakViewControllerDelegate>
#else
@interface WMFSettingsViewController () <UITableViewDelegate, WMFPreferredLanguagesViewControllerDelegate>
#endif

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;

@property (nonatomic, strong) SSSectionedDataSource *elementDataSource;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

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

    [self configureBackButton];

    [self.tableView registerNib:[WMFSettingsTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFSettingsTableViewCell identifier]];

    [self configureTableDataSource];

    self.tableView.estimatedRowHeight = 52.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.authManager = [WMFAuthenticationManager sharedInstance];
}

- (void)dealloc {
    self.authManager = nil;
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
    [self reloadVisibleCellOfType:WMFSettingsMenuItemType_Login];
}

- (void)configureBackButton {
    UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(closeButtonPressed)];
    self.navigationItem.leftBarButtonItems = @[xButton];
}

- (void)closeButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (nullable NSString *)title {
    return WMFLocalizedStringWithDefaultValue(@"settings-title", nil, nil, @"Settings", @"Title of the view where app settings are displayed.\n{{Identical|Settings}}");
}

- (void)configureTableDataSource {
    self.elementDataSource = [[SSSectionedDataSource alloc] init];
    self.elementDataSource.rowAnimation = UITableViewRowAnimationNone;
    self.elementDataSource.tableView = self.tableView;
    self.elementDataSource.cellClass = [WMFSettingsTableViewCell class];
    self.elementDataSource.tableActionBlock = ^BOOL(SSCellActionType action, UITableView *tableView, NSIndexPath *indexPath) {
        return NO;
    };

    @weakify(self)
        self.elementDataSource.cellConfigureBlock = ^(WMFSettingsTableViewCell *cell, WMFSettingsMenuItem *menuItem, UITableView *tableView, NSIndexPath *indexPath) {
            @strongify(self)
        cell.title = menuItem.title;
        cell.iconColor = menuItem.iconColor;
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

    };
    [self loadSections];
}

- (void)disclosureSwitchChanged:(UISwitch *)disclosureSwitch {
    WMFSettingsMenuItemType type = (WMFSettingsMenuItemType)disclosureSwitch.tag;
    [self updateStateForMenuItemType:type isSwitchOnValue:disclosureSwitch.isOn];
}

#pragma mark - Switch tap handling

- (void)updateStateForMenuItemType:(WMFSettingsMenuItemType)type isSwitchOnValue:(BOOL)isOn {
    switch (type) {
        case WMFSettingsMenuItemType_SendUsageReports:
            [SessionSingleton sharedInstance].shouldSendUsageReports = isOn;
            break;
        case WMFSettingsMenuItemType_ZeroWarnWhenLeaving:
            [SessionSingleton sharedInstance].zeroConfigurationManager.warnWhenLeaving = isOn;
            break;
        case WMFSettingsMenuItemType_SearchLanguageBarVisibility:
            [[NSUserDefaults wmf_userDefaults] wmf_setShowSearchLanguageBar:isOn];
        default:
            break;
    }
}

#pragma mark - Cell tap handling

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([(WMFSettingsMenuItem *)[self.elementDataSource itemAtIndexPath:indexPath] type]) {
        case WMFSettingsMenuItemType_Login:
            [self showLoginOrLogout];
            break;
        case WMFSettingsMenuItemType_SearchLanguage:
            [self showLanguages];
            break;
        case WMFSettingsMenuItemType_Notifications:
            [self showNotifications];
            break;
        case WMFSettingsMenuItemType_Support:
            [self wmf_openExternalUrl:[self donationURL] useSafari:YES];
            break;
        case WMFSettingsMenuItemType_PrivacyPolicy:
            [self wmf_openExternalUrl:[NSURL URLWithString:WMFSettingsURLPrivacyPolicy]];
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
            [self.navigationController pushViewController:vc animated:YES];
        } break;
        case WMFSettingsMenuItemType_About:
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[AboutViewController wmf_initialViewControllerFromClassStoryboard]]
                               animated:YES
                             completion:nil];
            break;
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

#pragma mark - Log in and out

- (void)showLoginOrLogout {
    NSString *userName = [WMFAuthenticationManager sharedInstance].loggedInUsername;
    if (userName) {
        [self showLogoutActionSheet];
    } else {
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[WMFLoginViewController wmf_initialViewControllerFromClassStoryboard]]
                           animated:YES
                         completion:nil];
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
                                                    [self reloadVisibleCellOfType:WMFSettingsMenuItemType_Login];
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
                                                [[WMFImageController sharedInstance] deleteTemporaryCache];
                                                [[WMFImageController sharedInstance] removeLegacyCache];
                                                [self.dataStore removeUnreferencedArticlesFromDiskCacheWithFailure:^(NSError *error) {
                                                    DDLogError(@"Error removing unreferenced articles: %@", error);
                                                } success:^{
                                                    DDLogDebug(@"Successfully removed unreferenced articles");
                                                }];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-cancel", nil, nil, @"Cancel", @"Cancel action to clear cached data\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];
    
    [self presentViewController:sheet animated:YES completion:NULL];
}

- (void)logout {
    [[WMFAuthenticationManager sharedInstance] logout];
}

#pragma mark - Languages

- (void)showLanguages {
    WMFPreferredLanguagesViewController *languagesVC = [WMFPreferredLanguagesViewController preferredLanguagesViewController];
    languagesVC.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC]
                       animated:YES
                     completion:nil];
}

- (void)languagesController:(WMFPreferredLanguagesViewController *)controller didUpdatePreferredLanguages:(NSArray<MWKLanguageLink *> *)languages {
    if ([languages count] > 1) {
        [[NSUserDefaults wmf_userDefaults] wmf_setShowSearchLanguageBar:YES];
    } else {
        [[NSUserDefaults wmf_userDefaults] wmf_setShowSearchLanguageBar:NO];
    }

    [self reloadVisibleCellOfType:WMFSettingsMenuItemType_SearchLanguage];
    [self reloadVisibleCellOfType:WMFSettingsMenuItemType_SearchLanguageBarVisibility];
}

#pragma mark - Notifications

- (void)showNotifications {
    NotificationSettingsViewController *notificationSettingsVC = [[NotificationSettingsViewController alloc] initWithNibName:@"NotificationSettingsViewController" bundle:nil];
    [self.navigationController pushViewController:notificationSettingsVC animated:YES];
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
        return ((WMFSettingsMenuItem *)[self.elementDataSource itemAtIndexPath:indexPath]).type == type;
    }];
}

- (void)reloadVisibleCellOfType:(WMFSettingsMenuItemType)type {
    NSIndexPath *indexPath = [self indexPathForVisibleCellOfType:type];
    if (indexPath) {
        [self.elementDataSource replaceItemAtIndexPath:indexPath withItem:[WMFSettingsMenuItem itemForType:type]];
    }
}

#pragma mark - Sections structure

- (void)loadSections {
    NSMutableArray *sections = [[NSMutableArray alloc] init];

    [sections addObject:[self section_1]];
    [sections addObject:[self section_2]];
    [sections addObject:[self section_3]];
    [sections addObject:[self section_4]];
    [sections addObject:[self section_5]];
    [sections wmf_safeAddObject:[self section_6]];

    [self.elementDataSource.sections setArray:sections];
    [self.elementDataSource.tableView reloadData];
}

#pragma mark - Section structure

- (SSSection *)section_1 {
    SSSection *section =
        [SSSection sectionWithItems:@[
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Login],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Support]
        ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

- (SSSection *)section_2 {
    NSArray *commonItems = @[[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SearchLanguage],
                             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SearchLanguageBarVisibility]];
    NSMutableArray *items = [NSMutableArray arrayWithArray:commonItems];
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:10]) {
        [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Notifications]];
    }
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ClearCache]];
    SSSection *section = [SSSection sectionWithItems:items];
    section.header = nil;
    section.footer = nil;
    return section;
}

- (SSSection *)section_3 {
    SSSection *section =
        [SSSection sectionWithItems:@[
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_PrivacyPolicy],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Terms],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendUsageReports]
        ]];
    section.header = WMFLocalizedStringWithDefaultValue(@"main-menu-heading-legal", nil, nil, @"Privacy and Terms", @"Header text for the legal section of the menu. Consider using something informal, but feel free to use a more literal translation of \"Legal info\" if it seems more appropriate.");
    section.footer = WMFLocalizedStringWithDefaultValue(@"preference-summary-eventlogging-opt-in", nil, nil, @"Allow Wikimedia Foundation to collect information about how you use the app to make the app better", @"Description of preference that when checked enables data collection of user behavior.");
    return section;
}

- (SSSection *)section_4 {
    SSSection *section =
        [SSSection sectionWithItems:@[
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ZeroWarnWhenLeaving],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ZeroFAQ]
        ]];
    section.header = WMFLocalizedStringWithDefaultValue(@"main-menu-heading-zero", nil, nil, @"Wikipedia Zero", @"Header text for the Wikipedia Zero section of the menu. ([http://wikimediafoundation.org/wiki/Wikipedia_Zero More information]).\n{{Identical|Wikipedia Zero}}");
    section.footer = nil;
    return section;
}

- (SSSection *)section_5 {
    SSSection *section =
        [SSSection sectionWithItems:@[
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_RateApp],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendFeedback],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_About]
        ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

- (nullable SSSection *)section_6 {
#ifndef ALPHA
    if (![[NSBundle mainBundle] wmf_shouldShowDebugMenu]) {
        return nil;
    }
#endif

    SSSection *section =
        [SSSection sectionWithItems:@[
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_DebugCrash],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_DevSettings]
        ]];
    section.header = WMFLocalizedStringWithDefaultValue(@"main-menu-heading-debug", nil, nil, @"Debug", @"Header text for the debug section of the menu. The debug menu is conditionally shown if in Xcode debug mode.\n{{Identical|Debug}}");
    section.footer = nil;
    return section;
}

#pragma - KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey,id> *)change context:(nullable void *)context    {
    if (context == &kvo_WMFSettingsViewController_authManager_loggedInUsername) {
        [self reloadVisibleCellOfType:WMFSettingsMenuItemType_Login];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end

NS_ASSUME_NONNULL_END
