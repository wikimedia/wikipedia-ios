#import "WMFSettingsMenuItem.h"
#import "Wikipedia-Swift.h"

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
        case WMFSettingsMenuItemType_LoginAccount: {
            // SINGLETONTODO
            NSString *userName = [MWKDataStore shared].authenticationManager.loggedInUsername;

            NSString *loginString = (userName) ? WMFCommonStrings.account : WMFLocalizedStringWithDefaultValue(@"main-menu-account-login", nil, nil, @"Log in", @"Button text for logging in. {{Identical|Log in}}");

            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:loginString
                                                 iconName:@"settings-user"
                                                iconColor:[UIColor wmf_colorWithHex:(userName ? 0xFF8E2B : 0x9AA0A7)]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:userName
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Support: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-support", nil, nil, @"Support Wikipedia", @"Title for button letting user make a donation.")
                                                 iconName:@"settings-support"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SearchLanguage: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings myLanguages]
                                                 iconName:@"settings-language"
                                                iconColor:[UIColor wmf_colorWithHex:0x1F95DE]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:[MWKDataStore.shared.languageLinkController.appLanguage.languageCode uppercaseString]
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Search: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings searchTitle]
                                                 iconName:@"settings-search"
                                                iconColor:[UIColor wmf_green50]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_ExploreFeed: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings exploreFeedTitle]
                                                 iconName:@"settings-explore"
                                                iconColor:[UIColor wmf_colorWithHex:0x5ac8fa]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:[NSUserDefaults standardUserDefaults].defaultTabType != WMFAppDefaultTabTypeExplore ? @"Off" : @"On"
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Notifications: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings notifications]
                                                 iconName:@"settings-notifications"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Appearance: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFCommonStrings.readingPreferences
                                                 iconName:@"settings-appearance"
                                                iconColor:[UIColor wmf_colorWithHex:0x000000]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:WMFAppearanceSettingsViewController.disclosureText
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_StorageAndSyncing: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings settingsStorageAndSyncing]
                                                 iconName:@"settings-saved-articles"
                                                iconColor:[UIColor wmf_colorWithHex:0x00b4ce]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_PrivacyPolicy: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-privacy-policy", nil, nil, @"Privacy policy", @"Button text for showing privacy policy {{Identical|Privacy policy}}")
                                                 iconName:@"settings-privacy"
                                                iconColor:[UIColor wmf_colorWithHex:0x884FDC]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Terms: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-terms-of-use", nil, nil, @"Terms of Use", @"Button text for showing site terms of use {{Identical|Terms of use}}")
                                                 iconName:@"settings-terms"
                                                iconColor:[UIColor wmf_colorWithHex:0x99A1A7]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SendUsageReports: {
            BOOL loggingEnabled = [WMFEventLoggingService sharedInstance].isEnabled;
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"preference-title-eventlogging-opt-in", nil, nil, @"Send usage reports", @"Title of preference that when checked enables data collection of user behavior.")
                                                 iconName:@"settings-analytics"
                                                iconColor:[UIColor wmf_colorWithHex:0x95D15A]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_Switch
                                           disclosureText:nil
                                               isSwitchOn:loggingEnabled];
        }
        case WMFSettingsMenuItemType_StorageAndSyncingDebug: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:@"Reading list danger zone"
                                                 iconName:@"settings-zero"
                                                iconColor:[UIColor wmf_colorWithHex:0x1F45DE]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_ZeroFAQ: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-zero-faq", nil, nil, @"Wikipedia Zero FAQ", @"Button text for showing the Wikipedia Zero Frequently Asked Questions (FAQ) document")
                                                 iconName:@"settings-faq"
                                                iconColor:[UIColor wmf_colorWithHex:0x99A1A7]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_RateApp: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-rate-app", nil, nil, @"Rate the app", @"Button text for showing the app in the app store so user can rate the app")
                                                 iconName:@"settings-rate"
                                                iconColor:[UIColor wmf_colorWithHex:0xFEA13D]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SendFeedback: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-help-and-feedback", nil, nil, @"Help and feedback", @"Title for showing showing a screen that displays the FAQ and allows users to submit bug reports")
                                                 iconName:@"settings-help-and-feedback"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_About: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-about", nil, nil, @"About the app", @"Button for showing information about the app.")
                                                 iconName:@"settings-about"
                                                iconColor:[UIColor wmf_colorWithHex:0x000000]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_ClearCache: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache", nil, nil, @"Clear cached data", @"Title for the 'Clear cached data' settings row")
                                                 iconName:@"settings-clear-cache"
                                                iconColor:[UIColor wmf_colorWithHex:0xFFBF02]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_None
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
