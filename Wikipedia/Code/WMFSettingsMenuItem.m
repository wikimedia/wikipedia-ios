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
            NSString *loginString = (userName) ? [MWLocalizedString(@"main-menu-account-title-logged-in", nil) stringByReplacingOccurrencesOfString:@"$1" withString:userName] : MWLocalizedString(@"main-menu-account-login", nil);

            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:loginString
                                                 iconName:@"settings-user"
                                                iconColor:[UIColor wmf_colorWithHex:(userName ? 0xFF8E2B : 0x9AA0A7) alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
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
        case WMFSettingsMenuItemType_SearchLanguage: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:MWLocalizedString(@"settings-my-languages", nil)
                                                 iconName:@"settings-language"
                                                iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:[[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode uppercaseString]
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SearchLanguageBarVisibility: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:MWLocalizedString(@"settings-language-bar", nil)
                                                 iconName:@"settings-search"
                                                iconColor:[UIColor wmf_green]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_Switch
                                           disclosureText:nil
                                               isSwitchOn:[[NSUserDefaults wmf_userDefaults] wmf_showSearchLanguageBar]];
        }
        case WMFSettingsMenuItemType_Notifications: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:MWLocalizedString(@"settings-notifications", nil)
                                                 iconName:@"settings-notifications"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_PrivacyPolicy: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:MWLocalizedString(@"main-menu-privacy-policy", nil)
                                                 iconName:@"settings-privacy"
                                                iconColor:[UIColor wmf_colorWithHex:0x884FDC alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Terms: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:MWLocalizedString(@"main-menu-terms-of-use", nil)
                                                 iconName:@"settings-terms"
                                                iconColor:[UIColor wmf_colorWithHex:0x99A1A7 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
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
        case WMFSettingsMenuItemType_ZeroWarnWhenLeaving: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:MWLocalizedString(@"zero-warn-when-leaving", nil)
                                                 iconName:@"settings-zero"
                                                iconColor:[UIColor wmf_colorWithHex:0x1F95DE alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_Switch
                                           disclosureText:nil
                                               isSwitchOn:[SessionSingleton sharedInstance].zeroConfigurationManager.warnWhenLeaving];
        }
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
        case WMFSettingsMenuItemType_RateApp: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:MWLocalizedString(@"main-menu-rate-app", nil)
                                                 iconName:@"settings-rate"
                                                iconColor:[UIColor wmf_colorWithHex:0xFEA13D alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SendFeedback: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:MWLocalizedString(@"settings-help-and-feedback", nil)
                                                 iconName:@"settings-help-and-feedback"
                                                iconColor:[UIColor wmf_colorWithHex:0xFF1B33 alpha:1.0]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
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
