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

// URLS
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

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureBackButton];

    [self.tableView registerNib:[WMFSettingsTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFSettingsTableViewCell identifier]];
    
    [self configureTableDataSource];

    self.tableView.estimatedRowHeight = 52.0;
    self.tableView.rowHeight          = UITableViewAutomaticDimension;
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
        
        @strongify(self)
        cell.disclosureText = [self getDisclosureTextForMenuItemType:menuItem.type];
        [cell.disclosureSwitch setOn:[self getSwitchOnValueForMenuItemType:menuItem.type]];
        
        [cell.disclosureSwitch bk_removeEventHandlersForControlEvents:UIControlEventValueChanged];
        [cell.disclosureSwitch bk_addEventHandler:^(UISwitch* sender){
            @strongify(self)
            [self handleSwitchValueChangedTo:sender.isOn forMenuItemType:menuItem.type];
        } forControlEvents:UIControlEventValueChanged];
        
    };
}

- (NSString*)title {
    return MWLocalizedString(@"settings-title", nil);
}

-(void)configureBackButton {
    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItems = @[xButton];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Reload data source on view will appear so any state changes made by presented
    // view controllers will automatically be reflected when they are dismissed.
    [self rebuildSections];
}

-(nullable NSString*)getDisclosureTextForMenuItemType:(WMFSettingsMenuItemType)type {
    switch (type) {
        case WMFSettingsMenuItemType_SearchLanguage:
            return [[SessionSingleton sharedInstance].searchSite.language uppercaseString];
            break;
        default:
            break;
    }
    return nil;
}

-(BOOL)getSwitchOnValueForMenuItemType:(WMFSettingsMenuItemType)type {
    switch (type) {
        case WMFSettingsMenuItemType_SendUsageReports:
            return [SessionSingleton sharedInstance].shouldSendUsageReports;
            break;
        case WMFSettingsMenuItemType_ZeroWarnWhenLeaving:
            return [SessionSingleton sharedInstance].zeroConfigState.warnWhenLeaving;
            break;
        default:
            return NO;
            break;
    }
}

-(void)handleSwitchValueChangedTo:(BOOL)isOn forMenuItemType:(WMFSettingsMenuItemType)type {
    switch (type) {
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

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    switch ([(WMFSettingsMenuItem*)[self.elementDataSource itemAtIndexPath:indexPath] type]) {
        case WMFSettingsMenuItemType_Login:{
            NSString* userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
            if (userName) {
                [self displayLogoutActionSheet];
            }else{
                [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[LoginViewController wmf_initialViewControllerFromClassStoryboard]] animated:YES completion:nil];
            }
        }
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
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[AboutViewController wmf_initialViewControllerFromClassStoryboard]] animated:YES completion:nil];
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
}

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

- (void)displayLogoutActionSheet {
    UIActionSheet* sheet = [UIActionSheet bk_actionSheetWithTitle:MWLocalizedString(@"main-menu-account-logout-are-you-sure", nil)];

    @weakify(self)
    [sheet bk_setDestructiveButtonWithTitle:MWLocalizedString(@"main-menu-account-logout", nil) handler:^{
        @strongify(self)
        [self logout];
        [self rebuildSections];
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

- (void)showLanguages {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.languageSelectionDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [[SessionSingleton sharedInstance] setSearchLanguage:language.languageCode];
    [[MWKLanguageLinkController sharedInstance] addPreferredLanguage:language];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

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

- (void)rebuildSections {
    [self.elementDataSource.sections setArray:@[
                              [self section_1],
                              [self section_2],
                              [self section_3],
                              [self section_4],
                              [self section_5],
                              [self section_6],
                              [self section_7]
                              ]];
    [self.elementDataSource.tableView reloadData];
}

-(SSSection*)section_1 {
    NSString* userName  = [SessionSingleton sharedInstance].keychainCredentials.userName;
    NSString *loginString = (userName) ? [MWLocalizedString(@"main-menu-account-title-logged-in", nil) stringByReplacingOccurrencesOfString:@"$1" withString:userName] : MWLocalizedString(@"main-menu-account-login", nil);
    
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_Login
                                           title:loginString
                                        iconName:@"settings-user"
                                       iconColor:[UIColor wmf_colorWithHex:(userName ? 0xFF8E2B : 0x9CA1A7) alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ViewController],
       
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_Support
                                           title:MWLocalizedString(@"settings-support", nil)
                                        iconName:@"settings-support"
                                       iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink]
       ]];
    section.header = @"";
    section.footer = @"";
    return section;
}

-(SSSection*)section_2 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_SearchLanguage
                                           title:MWLocalizedString(@"settings-project", nil)
                                        iconName:@"settings-project"
                                       iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText]
       ]];
    section.header = @"";
    section.footer = @"";
    return section;
}

-(SSSection*)section_3 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_PrivacyPolicy
                                           title:MWLocalizedString(@"main-menu-privacy-policy", nil)
                                        iconName:@"settings-privacy"
                                       iconColor:[UIColor wmf_colorWithHex:0x884FDC alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ViewController],
       
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_Terms
                                           title:MWLocalizedString(@"main-menu-terms-of-use", nil)
                                        iconName:@"settings-terms"
                                       iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ViewController],
       
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_SendUsageReports
                                           title:MWLocalizedString(@"preference_title_eventlogging_opt_in", nil)
                                        iconName:@"settings-analytics"
                                       iconColor:[UIColor wmf_colorWithHex:0x95D15A alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_Switch]
       ]];
    section.header = MWLocalizedString(@"main-menu-heading-legal", nil);
    section.footer = MWLocalizedString(@"preference_summary_eventlogging_opt_in", nil);
    return section;
}

-(SSSection*)section_4 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_ZeroWarnWhenLeaving
                                           title:MWLocalizedString(@"zero-warn-when-leaving", nil)
                                        iconName:@"settings-zero"
                                       iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_Switch],
       
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_ZeroFAQ
                                           title:MWLocalizedString(@"main-menu-zero-faq", nil)
                                        iconName:@"settings-faq"
                                       iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink]
       ]];
    section.header = MWLocalizedString(@"main-menu-heading-zero", nil);
    section.footer = @"";
    return section;
}

-(SSSection*)section_5 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_RateApp
                                           title:MWLocalizedString(@"main-menu-rate-app", nil)
                                        iconName:@"settings-rate"
                                       iconColor:[UIColor wmf_colorWithHex:0xFEA13D alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ViewController],
       
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_SendFeedback
                                           title:MWLocalizedString(@"main-menu-send-feedback", nil)
                                        iconName:@"settings-feedback"
                                       iconColor:[UIColor wmf_colorWithHex:0x00B18D alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ViewController]
       ]];
    section.header = @"";
    section.footer = @"";
    return section;
}

-(SSSection*)section_6 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_About
                                           title:MWLocalizedString(@"main-menu-about", nil)
                                        iconName:@"settings-about"
                                       iconColor:[UIColor wmf_colorWithHex:0x000000 alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ViewController],
       
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_FAQ
                                           title:MWLocalizedString(@"main-menu-faq", nil)
                                        iconName:@"settings-faq"
                                       iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink]
       ]];
    section.header = @"";
    section.footer = @"";
    return section;
}

-(SSSection*)section_7 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_DebugCrash
                                           title:MWLocalizedString(@"main-menu-debug-crash", nil)
                                        iconName:@"settings-crash"
                                       iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_None],
       
       [[WMFSettingsMenuItem alloc] initWithType:WMFSettingsMenuItemType_DevSettings
                                           title:MWLocalizedString(@"main-menu-debug-tweaks", nil)
                                        iconName:@"settings-dev"
                                       iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                  disclosureType:WMFSettingsMenuItemDisclosureType_ViewController]
       ]];
    section.header = MWLocalizedString(@"main-menu-heading-debug", nil);
    section.footer = @"";
    return section;
}

@end
