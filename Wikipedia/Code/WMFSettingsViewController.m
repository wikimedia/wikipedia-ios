#import "WMFSettingsTableViewCell.h"
#import "Wikipedia-Swift.h"
#import "NSUserActivity+WMFExtensions.h"
#import "WMFArticleDataStore.h"

// View Controllers
#import "WMFSettingsViewController.h"
#import "LoginViewController.h"
#import "WMFLanguagesViewController.h"
#import "AboutViewController.h"
#import "WMFHelpViewController.h"

// Models
#import "MWKLanguageLink.h"

// Frameworks
#import <HockeySDK/HockeySDK.h>
#import <Tweaks/FBTweakViewController.h>
#import <Tweaks/FBTweakStore.h>
#import <SSDataSources/SSDataSources.h>

// Other
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIView+WMFDefaultNib.h"
#import "SessionSingleton.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "MWKLanguageLinkController.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "NSBundle+WMFInfoUtils.h"
#import "WMFAuthenticationManager.h"
#import "Wikipedia-Swift.h"
@import BlocksKitUIKitExtensions;

#pragma mark - Static URLs

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFSettingsURLZeroFAQ = @"https://m.wikimediafoundation.org/wiki/Wikipedia_Zero_App_FAQ";
static NSString *const WMFSettingsURLTerms = @"https://m.wikimediafoundation.org/wiki/Terms_of_Use";
static NSString *const WMFSettingsURLRate = @"itms-apps://itunes.apple.com/app/id324715238";
static NSString *const WMFSettingsURLDonation = @"https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=<app-version>&uselang=<langcode>";
static NSString *const WMFSettingsURLPrivacyPolicy = @"https://m.wikimediafoundation.org/wiki/Privacy_policy";

@interface WMFSettingsViewController () <UITableViewDelegate, WMFPreferredLanguagesViewControllerDelegate, FBTweakViewControllerDelegate>

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;
@property (nonatomic, strong, readwrite) WMFArticleDataStore *previewStore;

@property (nonatomic, strong) SSSectionedDataSource *elementDataSource;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation WMFSettingsViewController

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store previewStore:(WMFArticleDataStore *)previewStore {
    NSParameterAssert(store);
    NSParameterAssert(previewStore);
    WMFSettingsViewController *vc = [WMFSettingsViewController wmf_initialViewControllerFromClassStoryboard];
    vc.dataStore = store;
    vc.previewStore = previewStore;
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

    [self.KVOControllerNonRetaining observe:[WMFAuthenticationManager sharedInstance]
                                    keyPath:WMF_SAFE_KEYPATH([WMFAuthenticationManager sharedInstance], loggedInUsername)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WMFSettingsViewController *observer, id object, NSDictionary *change) {
                                          [observer reloadVisibleCellOfType:WMFSettingsMenuItemType_Login];
                                      }];
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
    @weakify(self)
        UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX
                                                           handler:^(id sender) {
                                                               @strongify(self)
                                                                   [self dismissViewControllerAnimated:YES
                                                                                            completion:nil];
                                                           }];
    self.navigationItem.leftBarButtonItems = @[xButton];
}

- (nullable NSString *)title {
    return MWLocalizedString(@"settings-title", nil);
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

        [cell.disclosureSwitch bk_removeEventHandlersForControlEvents:UIControlEventValueChanged];
        [cell.disclosureSwitch bk_addEventHandler:^(UISwitch *sender) {
            @strongify(self)
                menuItem.isSwitchOn = sender.isOn;
            [self updateStateForMenuItemType:menuItem.type isSwitchOnValue:sender.isOn];
        }
                                 forControlEvents:UIControlEventValueChanged];
    };
    [self loadSections];
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
            WMFHelpViewController *vc = [[WMFHelpViewController alloc] initWithDataStore:self.dataStore previewStore:self.previewStore];
            [self.navigationController pushViewController:vc animated:YES];
        } break;
        case WMFSettingsMenuItemType_About:
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[AboutViewController wmf_initialViewControllerFromClassStoryboard]]
                               animated:YES
                             completion:nil];
            break;
        case WMFSettingsMenuItemType_DebugCrash:
            [[self class] generateTestCrash];
            break;
        case WMFSettingsMenuItemType_DevSettings: {
            FBTweakViewController *tweaksVC = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance]];
            tweaksVC.tweaksDelegate = self;
            [self presentViewController:tweaksVC animated:YES completion:nil];
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
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[LoginViewController wmf_initialViewControllerFromClassStoryboard]]
                           animated:YES
                         completion:nil];
    }
}

- (void)showLogoutActionSheet {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:MWLocalizedString(@"main-menu-account-logout-are-you-sure", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    @weakify(self)
        [sheet addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"main-menu-account-logout", nil)
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *_Nonnull action) {
                                                    @strongify(self)
                                                        [self logout];
                                                    [self reloadVisibleCellOfType:WMFSettingsMenuItemType_Login];
                                                }]];
    [sheet addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"main-menu-account-logout-cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];

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

- (void)tweakViewControllerPressedDone:(FBTweakViewController *)tweakViewController {
    [[NSNotificationCenter defaultCenter] postNotificationName:FBTweakShakeViewControllerDidDismissNotification object:tweakViewController];
    [tweakViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Cell reloading

- (nullable NSIndexPath *)indexPathForVisibleCellOfType:(WMFSettingsMenuItemType)type {
    return [self.tableView.indexPathsForVisibleRows bk_match:^BOOL(NSIndexPath *indexPath) {
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
    section.header = MWLocalizedString(@"main-menu-heading-legal", nil);
    section.footer = MWLocalizedString(@"preference_summary_eventlogging_opt_in", nil);
    return section;
}

- (SSSection *)section_4 {
    SSSection *section =
        [SSSection sectionWithItems:@[
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ZeroWarnWhenLeaving],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ZeroFAQ]
        ]];
    section.header = MWLocalizedString(@"main-menu-heading-zero", nil);
    section.footer = nil;
    return section;
}

- (SSSection *)section_5 {
    SSSection *section =
        [SSSection sectionWithItems:@[
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_RateApp],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendFeedback],
            [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_About],
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
    section.header = MWLocalizedString(@"main-menu-heading-debug", nil);
    section.footer = nil;
    return section;
}

@end

NS_ASSUME_NONNULL_END
