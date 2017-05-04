#import "WMFSettingsMenuItem.h"
#import "SessionSingleton.h"
#import "Wikipedia-Swift.h"
#import "MWKLanguageLinkController.h"

@interface WMFSettingsMenuItem ()

@property (nonatomic, assign, readwrite) WMFSettingsMenuItemType type;

@property (nonatomic, copy, readwrite) NSString *title;

@property (nonatomic, copy, readwrite) NSString *iconName;

@property (nonatomic, copy, readwrite) UIColor *iconColor;

@property (nonatomic, assign, readwrite) WMFSettingsMenuItemDisclosureType disclosureType;

@property (nonatomic, copy, readwrite) NSString *disclosureText;

@end

@implementation WMFSettingsMenuItem

+ (WMFSettingsMenuItem *)itemForType:(WMFSettingsMenuItemType)type {
    switch (type) {
        case WMFSettingsMenuItemType_Login: {
            NSString *userName = [WMFAuthenticationManager sharedInstance].loggedInUsername;
            NSString *loginString = (userName) ? [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"main-menu-account-title-logged-in", nil, nil, @"Logged in as %1$@", @"Header text used when account is logged in. %1$@ will be replaced with current username."), userName] : WMFLocalizedStringWithDefaultValue(@"main-menu-account-login", nil, nil, @"Log in", @"Button text for logging in.\n{{Identical|Log in}}");

            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:loginString
                                                 iconName:@"settings-user"
                                                iconColor:[UIColor wmf_colorWithHex:(userName ? 0xFF8E2B : 0x9AA0A7)alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Support: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-support", nil, nil, @"Support Wikipedia", @"Title for button letting user make a donation.")
                                                 iconName:@"settings-support"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SearchLanguage: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-my-languages", nil, nil, @"My languages", @"Title for list of user's preferred languages")
                                                 iconName:@"settings-language"
                                                iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:[[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode uppercaseString]
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SearchLanguageBarVisibility: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-language-bar", nil, nil, @"Show languages on search", @"Title in Settings for toggling the display the language bar in the search view")
                                                 iconName:@"settings-search"
                                                iconColor:[UIColor wmf_green]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_Switch
                                           disclosureText:nil
                                               isSwitchOn:[[NSUserDefaults wmf_userDefaults] wmf_showSearchLanguageBar]];
        }
        case WMFSettingsMenuItemType_Notifications: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-notifications", nil, nil, @"Notifications", @"Title for button letting user choose notifications settings.\n{{Identical|Notification}}")
                                                 iconName:@"settings-notifications"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_PrivacyPolicy: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-privacy-policy", nil, nil, @"Privacy policy", @"Button text for showing privacy policy\n{{Identical|Privacy policy}}")
                                                 iconName:@"settings-privacy"
                                                iconColor:[UIColor wmf_colorWithHex:0x884FDC alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Terms: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-terms-of-use", nil, nil, @"Terms of Use", @"Button text for showing site terms of use\n{{Identical|Terms of use}}")
                                                 iconName:@"settings-terms"
                                                iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SendUsageReports: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"preference-title-eventlogging-opt-in", nil, nil, @"Send usage reports", @"Title of preference that when checked enables data collection of user behavior.")
                                                 iconName:@"settings-analytics"
                                                iconColor:[UIColor wmf_colorWithHex:0x95D15A alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_Switch
                                           disclosureText:nil
                                               isSwitchOn:[SessionSingleton sharedInstance].shouldSendUsageReports];
        }
        case WMFSettingsMenuItemType_ZeroWarnWhenLeaving: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"zero-warn-when-leaving", nil, nil, @"Warn if leaving Zero", @"Main menu option to be warned if leaving Wikipedia Zero")
                                                 iconName:@"settings-zero"
                                                iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_Switch
                                           disclosureText:nil
                                               isSwitchOn:[SessionSingleton sharedInstance].zeroConfigurationManager.warnWhenLeaving];
        }
        case WMFSettingsMenuItemType_ZeroFAQ: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-zero-faq", nil, nil, @"Wikipedia Zero FAQ", @"Button text for showing the Wikipedia Zero Frequently Asked Questions (FAQ) document")
                                                 iconName:@"settings-faq"
                                                iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_RateApp: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-rate-app", nil, nil, @"Rate the app", @"Button text for showing the app in the app store so user can rate the app")
                                                 iconName:@"settings-rate"
                                                iconColor:[UIColor wmf_colorWithHex:0xFEA13D alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SendFeedback: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-help-and-feedback", nil, nil, @"Help and feedback", @"Title for showing showing a screen that displays the FAQ and allows users to submit bug reports")
                                                 iconName:@"settings-help-and-feedback"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_About: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-about", nil, nil, @"About the app", @"Button for showing information about the app.")
                                                 iconName:@"settings-about"
                                                iconColor:[UIColor wmf_colorWithHex:0x000000 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_ClearCache: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache", nil, nil, @"Clear cached data", @"Title for the 'Clear cached data' settings row")
                                                 iconName:@"settings-clear-cache"
                                                iconColor:[UIColor wmf_colorWithHex:0xFFBF02 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_None
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_DebugCrash: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-debug-crash", nil, nil, @"Crash", @"Title for button that forces the application to crash.\n{{Identical|Crash}}")
                                                 iconName:@"settings-crash"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_None
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_DevSettings: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-debug-tweaks", nil, nil, @"Developer settings", @"Title for button that shows debugging settings options.")
                                                 iconName:@"settings-dev"
                                                iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
    }
}

- (instancetype)initWithType:(WMFSettingsMenuItemType)type
                       title:(NSString *)title
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor
              disclosureType:(WMFSettingsMenuItemDisclosureType)disclosureType
              disclosureText:(NSString *)disclosureText
                  isSwitchOn:(BOOL)isSwitchOn {
    self = [super init];
    if (self) {
        self.type = type;
        self.title = title;
        self.iconName = iconName;
        self.iconColor = iconColor;
        self.disclosureType = disclosureType;
        self.disclosureText = disclosureText;
        self.isSwitchOn = isSwitchOn;
    }
    return self;
}

@end
