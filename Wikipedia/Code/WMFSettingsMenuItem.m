#import "WMFSettingsMenuItem.h"
#import "Wikipedia-Swift.h"
#import "WMFSettingsViewController.h"
@import WMFData;

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
            WMFAuthenticationManager *authManager = [MWKDataStore shared].authenticationManager;
            NSString *userName = authManager.authStatePermanentUsername;

            NSString *loginString = (userName) ? WMFCommonStrings.account : WMFLocalizedStringWithDefaultValue(@"main-menu-account-login", nil, nil, @"Log in", @"Button text for logging in. {{Identical|Log in}}");

            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:loginString
                                                 iconName:@"settings-user"
                                                iconColor: userName ? [UIColor wmf_orange] : [UIColor wmf_gray_400]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:userName
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Support: {
            return [[WMFSettingsMenuItem alloc] initWithType:type
                                                title:WMFLocalizedStringWithDefaultValue(@"settings-donate", nil, nil, @"Donate", @"Title for button letting user make a donation.")
                                             iconName:@"settings-support"
                                            iconColor:[UIColor wmf_red_600]
                                       disclosureType:WMFSettingsMenuItemDisclosureType_None
                                       disclosureText:nil
                                           isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SearchLanguage: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings myLanguages]
                                                 iconName:@"settings-language"
                                                iconColor:[UIColor wmf_blue_300]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:[MWKDataStore.shared.languageLinkController.appLanguage.languageCode uppercaseString]
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Search: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings searchTitle]
                                                 iconName:@"settings-search"
                                                iconColor:[UIColor wmf_green_600]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_ExploreFeed: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings exploreFeedTitle]
                                                 iconName:@"settings-explore"
                                                iconColor:[UIColor wmf_blue_300]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:[NSUserDefaults standardUserDefaults].defaultTabType != WMFAppDefaultTabTypeExplore ? WMFCommonStrings.offGenericTitle : WMFCommonStrings.onGenericTitle
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Notifications: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings pushNotifications]
                                                 iconName:@"settings-notifications"
                                                iconColor:[UIColor wmf_red_600]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_YearInReview: {
            WMFYearInReviewDataController *dataController = [WMFYearInReviewDataController dataControllerForObjectiveC];
            NSString *disclosureText = [dataController yearInReviewSettingsIsEnabled] ? WMFCommonStrings.onGenericTitle : WMFCommonStrings.offGenericTitle;
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings yirTitle]
                                                 iconName:@"settings-calendar"
                                                iconColor:[UIColor wmf_blue_600]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:disclosureText
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Appearance: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFCommonStrings.readingPreferences
                                                 iconName:@"settings-appearance"
                                                iconColor:[UIColor blackColor]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:WMFAppearanceSettingsViewController.disclosureText
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_StorageAndSyncing: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:[WMFCommonStrings settingsStorageAndSyncing]
                                                 iconName:@"settings-saved-articles"
                                                iconColor:[UIColor wmf_blue_300]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_PrivacyPolicy: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-privacy-policy", nil, nil, @"Privacy policy", @"Button text for showing privacy policy {{Identical|Privacy policy}}")
                                                 iconName:@"settings-privacy"
                                                iconColor:[UIColor wmf_purple]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_Terms: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-terms-of-use", nil, nil, @"Terms of Use", @"Button text for showing site terms of use {{Identical|Terms of use}}")
                                                 iconName:@"settings-terms"
                                                iconColor:[UIColor wmf_gray_400]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_StorageAndSyncingDebug: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:@"Reading list danger zone"
                                                 iconName:@"settings-zero"
                                                iconColor:[UIColor wmf_blue_700]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_ZeroFAQ: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-zero-faq", nil, nil, @"Wikipedia Zero FAQ", @"Button text for showing the Wikipedia Zero Frequently Asked Questions (FAQ) document")
                                                 iconName:@"settings-faq"
                                                iconColor:[UIColor wmf_gray_400]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_RateApp: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-rate-app", nil, nil, @"Rate the app", @"Button text for showing the app in the app store so user can rate the app")
                                                 iconName:@"settings-rate"
                                                iconColor:[UIColor wmf_orange]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ExternalLink
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_SendFeedback: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-help-and-feedback", nil, nil, @"Help and feedback", @"Title for showing showing a screen that displays the FAQ and allows users to submit bug reports")
                                                 iconName:@"settings-help-and-feedback"
                                                iconColor:[UIColor wmf_red_600]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_About: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"main-menu-about", nil, nil, @"About the app", @"Button for showing information about the app.")
                                                 iconName:@"settings-about"
                                                iconColor:[UIColor blackColor]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_ViewController
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_ClearCache: {
            return
                [[WMFSettingsMenuItem alloc] initWithType:type
                                                    title:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache", nil, nil, @"Clear cached data", @"Title for the 'Clear cached data' settings row")
                                                 iconName:@"settings-clear-cache"
                                                iconColor:[UIColor wmf_yellow_600]
                                           disclosureType:WMFSettingsMenuItemDisclosureType_None
                                           disclosureText:nil
                                               isSwitchOn:NO];
        }
        case WMFSettingsMenuItemType_DonateHistory: {
            return [[WMFSettingsMenuItem alloc] initWithType:type
                                                       title: WMFCommonStrings.deleteDonationHistory
                                                    iconName:@"settings-support"
                                                   iconColor:[UIColor wmf_gray_400]
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
