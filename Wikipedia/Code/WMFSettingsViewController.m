//  Created by Monte Hurd on 12/18/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

// Views
#import "WMFSettingsTableViewCell.h"

// View Controllers
#import "WMFSettingsViewController.h"
#import "LoginViewController.h"
#import "LanguagesViewController.h"
#import "AboutViewController.h"

// Models
#import "MWKLanguageLink.h"

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
#import "MWKSite.h"
#import "NSBundle+WMFInfoUtils.h"
#import "UIColor+WMFHexColor.h"

#pragma mark - Static URLs

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

-(void)configureBackButton {
    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItems = @[xButton];
}

- (NSString*)title {
    return MWLocalizedString(@"settings-title", nil);
}

-(void)configureTableDataSource {
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
            [self updateStateForMenuItem:menuItem isSwitchOnValue:sender.isOn];
        } forControlEvents:UIControlEventValueChanged];
        
    };
    [self loadSections];
}

#pragma mark - Teardown

-(void)dealloc {
    if ([SessionSingleton sharedInstance].keychainCredentials) {
        [self.KVOControllerNonRetaining unobserve:[SessionSingleton sharedInstance].keychainCredentials
                                          keyPath:WMF_SAFE_KEYPATH([SessionSingleton sharedInstance].keychainCredentials, userName)];
    }
}

#pragma mark - Switch tap handling

-(void)updateStateForMenuItem:(WMFSettingsMenuItem*)menuItem isSwitchOnValue:(BOOL)isOn{
    switch (menuItem.type) {
        case WMFSettingsMenuItemType_SendUsageReports:
            [SessionSingleton sharedInstance].shouldSendUsageReports = isOn;
            break;
        case WMFSettingsMenuItemType_ZeroWarnWhenLeaving:
            [SessionSingleton sharedInstance].zeroConfigState.warnWhenLeaving = isOn;
            break;
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
            [self wmf_openExternalUrl:[NSURL URLWithString:WMFSettingsURLRate]];
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

-(NSURL*)donationURL {
    NSString *url = WMFSettingsURLSupport;
    
    NSString *languageCode = [SessionSingleton sharedInstance].searchSite.language;
    languageCode = [languageCode stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *appVersion = [[NSBundle mainBundle] wmf_debugVersion];
    appVersion = [appVersion stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    url = [url stringByReplacingOccurrencesOfString:@"<langcode>" withString:languageCode];
    url = [url stringByReplacingOccurrencesOfString:@"<app-version>" withString:appVersion];
    
    return [NSURL URLWithString:url];
}

-(NSURL*)emailURL {
    NSString* mailURL = [WMFSettingsURLEmail stringByAppendingString:[WikipediaAppUtils versionedUserAgent]];
    return [NSURL URLWithString:[mailURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark - Log in and out

-(void)showLoginOrLogout {
    NSString* userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
    if (userName) {
        [self showLogoutActionSheet];
    }else{
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[LoginViewController wmf_initialViewControllerFromClassStoryboard]]
                           animated:YES
                         completion:nil];
    }
}

- (void)showLogoutActionSheet {
    UIActionSheet* sheet = [UIActionSheet bk_actionSheetWithTitle:MWLocalizedString(@"main-menu-account-logout-are-you-sure", nil)];

    @weakify(self)
    [sheet bk_setDestructiveButtonWithTitle:MWLocalizedString(@"main-menu-account-logout", nil) handler:^{
        @strongify(self)
        [self logout];
        [self reloadVisibleCellOfType:WMFSettingsMenuItemType_Login];
    }];
    
    [sheet bk_setCancelButtonWithTitle:MWLocalizedString(@"main-menu-account-logout-cancel", nil) handler:nil];
    [sheet showInView:self.view];
}

-(void)logout {
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
    [[SessionSingleton sharedInstance] setSearchLanguage:language.languageCode];
    [[MWKLanguageLinkController sharedInstance] addPreferredLanguage:language];
    
    [self reloadVisibleCellOfType:WMFSettingsMenuItemType_SearchLanguage];
    
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

-(nullable NSIndexPath*)indexPathOfVisibleCellOfType:(WMFSettingsMenuItemType)type {
    return [self.tableView.indexPathsForVisibleRows bk_match:^BOOL (NSIndexPath* indexPath) {
        return ((WMFSettingsMenuItem*)[self.elementDataSource itemAtIndexPath:indexPath]).type == type;
    }];
}

-(void)reloadVisibleCellOfType:(WMFSettingsMenuItemType)type {
    NSIndexPath *indexPath = [self indexPathOfVisibleCellOfType:type];
    if (indexPath) {
        [self.elementDataSource replaceItemAtIndexPath:indexPath withItem:[self itemForType:type]];
    }
}

#pragma mark - Sections structure

- (void)loadSections {
    NSMutableArray *sections = [[NSMutableArray alloc] init];
    
    [sections wmf_safeAddObject:[self section_1]];
    [sections wmf_safeAddObject:[self section_2]];
    [sections wmf_safeAddObject:[self section_3]];
    [sections wmf_safeAddObject:[self section_4]];
    [sections wmf_safeAddObject:[self section_5]];
    [sections wmf_safeAddObject:[self section_6]];
    [sections wmf_safeAddObject:[self section_7]];
    
    [self.elementDataSource.sections setArray:sections];
    [self.elementDataSource.tableView reloadData];
}

#pragma mark - Section structure

-(SSSection*)section_1 {
    SSSection* section =
    [SSSection sectionWithItems:@[
                                  [self itemForType:WMFSettingsMenuItemType_Login],
                                  [self itemForType:WMFSettingsMenuItemType_Support]
                                  ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

-(SSSection*)section_2 {
    SSSection* section =
    [SSSection sectionWithItems:@[
                                  [self itemForType:WMFSettingsMenuItemType_SearchLanguage]
                                  ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

-(SSSection*)section_3 {
    SSSection* section =
    [SSSection sectionWithItems:@[
                                  [self itemForType:WMFSettingsMenuItemType_PrivacyPolicy],
                                  [self itemForType:WMFSettingsMenuItemType_Terms],
                                  [self itemForType:WMFSettingsMenuItemType_SendUsageReports]
                                  ]];
    section.header = MWLocalizedString(@"main-menu-heading-legal", nil);
    section.footer = MWLocalizedString(@"preference_summary_eventlogging_opt_in", nil);
    return section;
}

-(SSSection*)section_4 {
    SSSection* section =
    [SSSection sectionWithItems:@[
                                  [self itemForType:WMFSettingsMenuItemType_ZeroWarnWhenLeaving],
                                  [self itemForType:WMFSettingsMenuItemType_ZeroFAQ]
                                  ]];
    section.header = MWLocalizedString(@"main-menu-heading-zero", nil);
    section.footer = nil;
    return section;
}

-(SSSection*)section_5 {
    SSSection* section =
    [SSSection sectionWithItems:@[
                                  [self itemForType:WMFSettingsMenuItemType_RateApp],
                                  [self itemForType:WMFSettingsMenuItemType_SendFeedback]
                                  ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

-(SSSection*)section_6 {
    SSSection* section =
    [SSSection sectionWithItems:@[
                                  [self itemForType:WMFSettingsMenuItemType_About],
                                  [self itemForType:WMFSettingsMenuItemType_FAQ]
                                  ]];
    section.header = nil;
    section.footer = nil;
    return section;
}

-(SSSection*)section_7 {
    if (![[NSBundle mainBundle] wmf_shouldShowDebugMenu]) {
        return nil;
    }
    
    SSSection* section =
    [SSSection sectionWithItems: @[
                                   [self itemForType:WMFSettingsMenuItemType_DebugCrash],
                                   [self itemForType:WMFSettingsMenuItemType_DevSettings]
                                   ]];
    section.header = MWLocalizedString(@"main-menu-heading-debug", nil);
    section.footer = nil;
    return section;
}

#pragma mark - Row structure

- (WMFSettingsMenuItem*)itemForType:(WMFSettingsMenuItemType)type {
    switch (type) {
        case WMFSettingsMenuItemType_Login: {
            
            NSString* userName  = [SessionSingleton sharedInstance].keychainCredentials.userName;
            NSString *loginString = (userName) ? [MWLocalizedString(@"main-menu-account-title-logged-in", nil) stringByReplacingOccurrencesOfString:@"$1" withString:userName] : MWLocalizedString(@"main-menu-account-login", nil);
            
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:loginString
                                             iconName:@"settings-user"
                                            iconColor:[UIColor wmf_colorWithHex:(userName ? 0xFF8E2B : 0x9CA1A7) alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
            break;
        case WMFSettingsMenuItemType_Support: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"settings-support", nil)
                                             iconName:@"settings-support"
                                            iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                       disclosureText:nil
                                           isSwitchOn:NO];

        }
            break;
            
        case WMFSettingsMenuItemType_SearchLanguage: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"settings-project", nil)
                                             iconName:@"settings-project"
                                            iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                       disclosureText:[[SessionSingleton sharedInstance].searchSite.language uppercaseString]
                                           isSwitchOn:NO];
        }
            break;
        case WMFSettingsMenuItemType_PrivacyPolicy: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-privacy-policy", nil)
                                             iconName:@"settings-privacy"
                                            iconColor:[UIColor wmf_colorWithHex:0x884FDC alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                       disclosureText:nil
                                           isSwitchOn:NO];

        }
            break;
        case WMFSettingsMenuItemType_Terms: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-terms-of-use", nil)
                                             iconName:@"settings-terms"
                                            iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                       disclosureText:nil
                                           isSwitchOn:NO];

        }
            break;
        case WMFSettingsMenuItemType_SendUsageReports: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"preference_title_eventlogging_opt_in", nil)
                                             iconName:@"settings-analytics"
                                            iconColor:[UIColor wmf_colorWithHex:0x95D15A alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_Switch
                                       disclosureText:nil
                                           isSwitchOn:[SessionSingleton sharedInstance].shouldSendUsageReports];

        }
            break;
        case WMFSettingsMenuItemType_ZeroWarnWhenLeaving: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"zero-warn-when-leaving", nil)
                                             iconName:@"settings-zero"
                                            iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_Switch
                                       disclosureText:nil
                                           isSwitchOn:[SessionSingleton sharedInstance].zeroConfigState.warnWhenLeaving];
        }
            break;
        case WMFSettingsMenuItemType_ZeroFAQ: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-zero-faq", nil)
                                             iconName:@"settings-faq"
                                            iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
            break;
        case WMFSettingsMenuItemType_RateApp: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-rate-app", nil)
                                             iconName:@"settings-rate"
                                            iconColor:[UIColor wmf_colorWithHex:0xFEA13D alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
            break;
        case WMFSettingsMenuItemType_SendFeedback: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-send-feedback", nil)
                                             iconName:@"settings-feedback"
                                            iconColor:[UIColor wmf_colorWithHex:0x00B18D alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
            break;
        case WMFSettingsMenuItemType_About: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-about", nil)
                                             iconName:@"settings-about"
                                            iconColor:[UIColor wmf_colorWithHex:0x000000 alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
            break;
        case WMFSettingsMenuItemType_FAQ: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-faq", nil)
                                             iconName:@"settings-faq"
                                            iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
            break;
        case WMFSettingsMenuItemType_DebugCrash: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-debug-crash", nil)
                                             iconName:@"settings-crash"
                                            iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_None
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
            break;
        case WMFSettingsMenuItemType_DevSettings: {
            return
            [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:MWLocalizedString(@"main-menu-debug-tweaks", nil)
                                             iconName:@"settings-dev"
                                            iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
            break;
    }
}

@end
