//  Created by Monte Hurd on 12/18/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

// Views
#import "WMFSettingsTableViewCell.h"
#import "Wikipedia-Swift.h"

// View Controllers
#import "WMFSettingsViewController.h"
#import "LoginViewController.h"
#import "LanguagesViewController.h"
#import "AboutViewController.h"

// Models
#import "MWKLanguageLink.h"
#import "MWKSite.h"

// Utils
#import "WikipediaAppUtils.h"

// Frameworks
#import <HockeySDK/HockeySDK.h>
#import <BlocksKit/BlocksKit+UIKit.h>
@import Tweaks;
@import SSDataSources;

// Other
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIView+WMFDefaultNib.h"
#import "SessionSingleton.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "MWKLanguageLinkController.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "NSBundle+WMFInfoUtils.h"

#pragma mark - Static URLs

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFSettingsURLZeroFAQ = @"https://m.wikimediafoundation.org/wiki/Wikipedia_Zero_App_FAQ";
static NSString* const WMFSettingsURLTerms   = @"https://m.wikimediafoundation.org/wiki/Terms_of_Use";
static NSString* const WMFSettingsURLRate    = @"itms-apps://itunes.apple.com/app/id324715238";
static NSString* const WMFSettingsURLFAQ     = @"https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ";
static NSString* const WMFSettingsURLEmail   = @"mailto:mobile-ios-wikipedia@wikimedia.org?subject=Feedback:";
static NSString* const WMFSettingsURLSupport = @"https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=<app-version>&uselang=<langcode>";

@interface WMFSettingsViewController () <UITableViewDelegate, LanguageSelectionDelegate, FBTweakViewControllerDelegate>

@property (nonatomic, strong) SSSectionedDataSource* elementDataSource;
@property (strong, nonatomic) IBOutlet UITableView* tableView;

@end


@implementation WMFSettingsViewController

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureBackButton];

    [self.tableView registerNib:[WMFSettingsTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFSettingsTableViewCell identifier]];

    [self configureTableDataSource];

    self.tableView.estimatedRowHeight = 52.0;
    self.tableView.rowHeight          = UITableViewAutomaticDimension;

    [self.KVOControllerNonRetaining observe:[SessionSingleton sharedInstance].keychainCredentials
                                    keyPath:WMF_SAFE_KEYPATH([SessionSingleton sharedInstance].keychainCredentials, userName)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WMFSettingsViewController* observer, id object, NSDictionary* change) {
        [observer reloadVisibleCellOfType:WMFSettingsMenuItemType_Login];
    }];
}

- (void)configureBackButton {
    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItems = @[xButton];
}

- (nullable NSString*)title {
    return MWLocalizedString(@"settings-title", nil);
}

- (void)configureTableDataSource {
    self.elementDataSource                  = [[SSSectionedDataSource alloc] init];
    self.elementDataSource.rowAnimation     = UITableViewRowAnimationNone;
    self.elementDataSource.tableView        = self.tableView;
    self.elementDataSource.cellClass        = [WMFSettingsTableViewCell class];
    self.elementDataSource.tableActionBlock = ^BOOL (SSCellActionType action, UITableView* tableView, NSIndexPath* indexPath) {
        return NO;
    };

    @weakify(self)
    self.elementDataSource.cellConfigureBlock = ^(WMFSettingsTableViewCell* cell, WMFSettingsMenuItem* menuItem, UITableView* tableView, NSIndexPath* indexPath) {
        cell.title          = menuItem.title;
        cell.iconColor      = menuItem.iconColor;
        cell.iconName       = menuItem.iconName;
        cell.disclosureType = menuItem.disclosureType;
        cell.disclosureText = menuItem.disclosureText;
        [cell.disclosureSwitch setOn:menuItem.isSwitchOn];
        cell.selectionStyle = (menuItem.disclosureType == WMFSettingsMenuItemDisclosureType_Switch) ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

        [cell.disclosureSwitch bk_removeEventHandlersForControlEvents:UIControlEventValueChanged];
        [cell.disclosureSwitch bk_addEventHandler:^(UISwitch* sender){
            @strongify(self)
            menuItem.isSwitchOn = sender.isOn;
            [self updateStateForMenuItemType:menuItem.type isSwitchOnValue:sender.isOn];
        } forControlEvents:UIControlEventValueChanged];
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
            [SessionSingleton sharedInstance].zeroConfigState.warnWhenLeaving = isOn;
            break;
        case WMFSettingsMenuItemType_SearchLanguageBarVisibility:
            [[NSUserDefaults standardUserDefaults] wmf_setShowSearchLanguageBar:isOn];
        default:
            break;
    }
}

#pragma mark - Cell tap handling

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    switch ([(WMFSettingsMenuItem*)[self.elementDataSource itemAtIndexPath:indexPath] type]) {
        case WMFSettingsMenuItemType_Login:
            [self showLoginOrLogout];
            break;
        case WMFSettingsMenuItemType_SearchLanguage:
            [self showLanguages];
            break;
        case WMFSettingsMenuItemType_Support:
            [self wmf_openExternalUrl:[self donationURL]];
            break;
        case WMFSettingsMenuItemType_PrivacyPolicy:
            [self wmf_openExternalUrl:[NSURL URLWithString:URL_PRIVACY_POLICY]];
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
        case WMFSettingsMenuItemType_SendFeedback:
            [self wmf_openExternalUrl:[self emailURL]];
            break;
        case WMFSettingsMenuItemType_About:
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[AboutViewController wmf_initialViewControllerFromClassStoryboard]]
                               animated:YES
                             completion:nil];
            break;
        case WMFSettingsMenuItemType_FAQ:
            [self wmf_openExternalUrl:[NSURL URLWithString:WMFSettingsURLFAQ]];
            break;
        case WMFSettingsMenuItemType_DebugCrash:
            [[self class] generateTestCrash];
            break;
        case WMFSettingsMenuItemType_DevSettings: {
            FBTweakViewController* tweaksVC = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance]];
            tweaksVC.tweaksDelegate = self;
            [self presentViewController:tweaksVC animated:YES completion:nil];
        }
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Dynamic URLs

- (NSURL*)donationURL {
    NSString* url = WMFSettingsURLSupport;

    NSString* languageCode = [NSUserDefaults standardUserDefaults].wmf_appSite.language;
    languageCode = [languageCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSString* appVersion = [[NSBundle mainBundle] wmf_debugVersion];
    appVersion = [appVersion stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    url = [url stringByReplacingOccurrencesOfString:@"<langcode>" withString:languageCode];
    url = [url stringByReplacingOccurrencesOfString:@"<app-version>" withString:appVersion];

    return [NSURL URLWithString:url];
}

- (NSURL*)emailURL {
    NSString* mailURL = [WMFSettingsURLEmail stringByAppendingString:[WikipediaAppUtils versionedUserAgent]];
    return [NSURL URLWithString:[mailURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark - Log in and out

- (void)showLoginOrLogout {
    NSString* userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
    if (userName) {
        [self showLogoutActionSheet];
    } else {
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[LoginViewController wmf_initialViewControllerFromClassStoryboard]]
                           animated:YES
                         completion:nil];
    }
}

- (void)showLogoutActionSheet {
    UIActionSheet* sheet = [UIActionSheet bk_actionSheetWithTitle:MWLocalizedString(@"main-menu-account-logout-are-you-sure", nil)];

    @weakify(self)
    [sheet bk_setDestructiveButtonWithTitle : MWLocalizedString(@"main-menu-account-logout", nil) handler :^{
        @strongify(self)
        [self logout];
        [self reloadVisibleCellOfType:WMFSettingsMenuItemType_Login];
    }];

    [sheet bk_setCancelButtonWithTitle:MWLocalizedString(@"main-menu-account-logout-cancel", nil) handler:nil];
    [sheet showInView:self.view];
}

- (void)logout {
    //TODO: find better home for this.
    [SessionSingleton sharedInstance].keychainCredentials.userName   = nil;
    [SessionSingleton sharedInstance].keychainCredentials.password   = nil;
    [SessionSingleton sharedInstance].keychainCredentials.editTokens = nil;
    // Clear session cookies too.
    for (NSHTTPCookie* cookie in[[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

#pragma mark - Languages

- (void)showLanguages {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.languageSelectionDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC]
                       animated:YES
                     completion:nil];
}

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    if ([[language site] isEqualToSite:[NSUserDefaults standardUserDefaults].wmf_appSite]) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] wmf_setShowSearchLanguageBar:YES];
    [[NSUserDefaults standardUserDefaults] wmf_setAppSite:[language site]];
    [[MWKLanguageLinkController sharedInstance] addPreferredLanguage:language];

    [self reloadVisibleCellOfType:WMFSettingsMenuItemType_SearchLanguage];
    [self reloadVisibleCellOfType:WMFSettingsMenuItemType_SearchLanguageBarVisibility];

    [self dismissViewControllerAnimated:YES completion:NULL];
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

- (void)tweakViewControllerPressedDone:(FBTweakViewController*)tweakViewController {
    [tweakViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Cell reloading

- (nullable NSIndexPath*)indexPathForVisibleCellOfType:(WMFSettingsMenuItemType)type {
    return [self.tableView.indexPathsForVisibleRows bk_match:^BOOL (NSIndexPath* indexPath) {
        return ((WMFSettingsMenuItem*)[self.elementDataSource itemAtIndexPath:indexPath]).type == type;
    }];
}

- (void)reloadVisibleCellOfType:(WMFSettingsMenuItemType)type {
    NSIndexPath* indexPath = [self indexPathForVisibleCellOfType:type];
    if (indexPath) {
        [self.elementDataSource replaceItemAtIndexPath:indexPath withItem:[WMFSettingsMenuItem itemForType:type]];
    }
}

#pragma mark - Sections structure

- (void)loadSections {
    NSMutableArray* sections = [[NSMutableArray alloc] init];

    [sections addObject:[self section_1]];
    [sections addObject:[self section_2]];
    [sections addObject:[self section_3]];
    [sections addObject:[self section_4]];
    [sections addObject:[self section_5]];
    [sections addObject:[self section_6]];
    [sections wmf_safeAddObject:[self section_7]];

    [self.elementDataSource.sections setArray:sections];
    [self.elementDataSource.tableView reloadData];
}

#pragma mark - Section structure

- (SSSection*)section_1 {
    SSSection* section =
        [SSSection sectionWithItems:@[
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Login],
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Support]
         ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

- (SSSection*)section_2 {
    SSSection* section =
        [SSSection sectionWithItems:@[
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SearchLanguage],
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SearchLanguageBarVisibility]
         ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

- (SSSection*)section_3 {
    SSSection* section =
        [SSSection sectionWithItems:@[
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_PrivacyPolicy],
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Terms],
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendUsageReports]
         ]];
    section.header = MWLocalizedString(@"main-menu-heading-legal", nil);
    section.footer = MWLocalizedString(@"preference_summary_eventlogging_opt_in", nil);
    return section;
}

- (SSSection*)section_4 {
    SSSection* section =
        [SSSection sectionWithItems:@[
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ZeroWarnWhenLeaving],
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ZeroFAQ]
         ]];
    section.header = MWLocalizedString(@"main-menu-heading-zero", nil);
    section.footer = nil;
    return section;
}

- (SSSection*)section_5 {
    SSSection* section =
        [SSSection sectionWithItems:@[
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_RateApp],
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendFeedback]
         ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

- (SSSection*)section_6 {
    SSSection* section =
        [SSSection sectionWithItems:@[
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_About],
             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_FAQ]
         ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

- (nullable SSSection*)section_7 {
    if (![[NSBundle mainBundle] wmf_shouldShowDebugMenu]) {
        return nil;
    }

    SSSection* section =
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
