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
#import "WMFSettingsDataSource.h"
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

// Constants
static NSString* const WMFSettingsURLZeroFAQ = @"https://m.wikimediafoundation.org/wiki/Wikipedia_Zero_App_FAQ";
static NSString* const WMFSettingsURLTerms   = @"https://m.wikimediafoundation.org/wiki/Terms_of_Use";
static NSString* const WMFSettingsURLRate    = @"itms-apps://itunes.apple.com/app/id324715238";
static NSString* const WMFSettingsURLSupport = @"https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=<app-version>&uselang=<langcode>";

@interface WMFSettingsViewController () <UITableViewDelegate, LanguageSelectionDelegate, FBTweakViewControllerDelegate>

@property (nonatomic, strong) WMFSettingsDataSource *elementDataSource;
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
    
    self.tableView.delegate = self;
}

-(void)configureTableDataSource {
    self.elementDataSource = [[WMFSettingsDataSource alloc] init];
    self.elementDataSource.rowAnimation = UITableViewRowAnimationNone;
    self.elementDataSource.tableView = self.tableView;
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
    [self.elementDataSource rebuildSections];
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
        case WMFSettingsMenuItemType_SendUsageReports:
            [SessionSingleton sharedInstance].shouldSendUsageReports = ![SessionSingleton sharedInstance].shouldSendUsageReports;
            [self.elementDataSource rebuildSections];
            break;
        case WMFSettingsMenuItemType_ZeroWarnWhenLeaving:
            [[SessionSingleton sharedInstance].zeroConfigState toggleWarnWhenLeaving];
            [self.elementDataSource rebuildSections];
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
            [self wmf_openExternalUrl:
             [NSURL URLWithString:@"https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ"]];
            break;
        case WMFSettingsMenuItemType_DebugCrash:
            [[self class] generateTestCrash];
            break;
        case WMFSettingsMenuItemType_DevSettings: {
            FBTweakViewController* tweaksVC = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance]];
            tweaksVC.tweaksDelegate = self;
            [self presentViewController:tweaksVC animated:YES completion:nil];
        }
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
    NSString* mailURL =
    [NSString stringWithFormat:@"mailto:mobile-ios-wikipedia@wikimedia.org?subject=Feedback:%@", [WikipediaAppUtils versionedUserAgent]];
    return [NSURL URLWithString:[mailURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)displayLogoutActionSheet {
    UIActionSheet* sheet = [UIActionSheet bk_actionSheetWithTitle:MWLocalizedString(@"main-menu-account-logout-are-you-sure", nil)];

    @weakify(self)
    [sheet bk_setDestructiveButtonWithTitle:MWLocalizedString(@"main-menu-account-logout", nil) handler:^{
        @strongify(self)
        [self logout];
        [self.elementDataSource rebuildSections];
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

@end
