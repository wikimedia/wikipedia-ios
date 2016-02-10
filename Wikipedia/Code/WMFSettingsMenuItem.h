
#import <Mantle/Mantle.h>

typedef NS_ENUM (NSUInteger, WMFSettingsMenuItemDisclosureType){
    WMFSettingsMenuItemDisclosureType_None,
    WMFSettingsMenuItemDisclosureType_ViewController,
    WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText,
    WMFSettingsMenuItemDisclosureType_ExternalLink,
    WMFSettingsMenuItemDisclosureType_Switch
};

typedef NS_ENUM (NSUInteger, WMFSettingsMenuItemType) {
    WMFSettingsMenuItemType_Login,                  //SECONDARY_MENU_ROW_INDEX_LOGIN,
    WMFSettingsMenuItemType_SearchLanguage,         //SECONDARY_MENU_ROW_INDEX_SEARCH_LANGUAGE,
    WMFSettingsMenuItemType_PrivacyPolicy,          //SECONDARY_MENU_ROW_INDEX_PRIVACY_POLICY
    WMFSettingsMenuItemType_Terms,                  //SECONDARY_MENU_ROW_INDEX_TERMS
    WMFSettingsMenuItemType_SendUsageReports,       //SECONDARY_MENU_ROW_INDEX_SEND_USAGE_REPORTS
    WMFSettingsMenuItemType_ZeroWarnWhenLeaving,    //SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING
    WMFSettingsMenuItemType_ZeroFAQ,                //SECONDARY_MENU_ROW_INDEX_ZERO_FAQ
    WMFSettingsMenuItemType_RateApp,                //SECONDARY_MENU_ROW_INDEX_RATE_APP
    WMFSettingsMenuItemType_SendFeedback,           //SECONDARY_MENU_ROW_INDEX_SEND_FEEDBACK
    WMFSettingsMenuItemType_About,                  //SECONDARY_MENU_ROW_INDEX_ABOUT
    WMFSettingsMenuItemType_FAQ,                    //SECONDARY_MENU_ROW_INDEX_FAQ
    WMFSettingsMenuItemType_DebugCrash,             //SECONDARY_MENU_ROW_INDEX_DEBUG_CRASH
    WMFSettingsMenuItemType_DevSettings             //SECONDARY_MENU_ROW_INDEX_DEBUG_TWEAKS
};

@interface WMFSettingsMenuItem : MTLModel

@property (nonatomic, assign, readonly) WMFSettingsMenuItemType type;

@property (nonatomic, copy, readonly) NSString* title;

@property (nonatomic, copy, readonly) NSString* iconName;

@property (nonatomic, copy, readonly) UIColor* iconColor;

@property (nonatomic, assign, readonly) WMFSettingsMenuItemDisclosureType disclosureType;

@property (nonatomic, copy, readonly) NSString* disclosureText;

- (instancetype)initWithType:(WMFSettingsMenuItemType)type
                       title:(NSString*)title
                    iconName:(NSString*)iconName
                   iconColor:(UIColor*)iconColor
              disclosureType:(WMFSettingsMenuItemDisclosureType)disclosureType
              disclosureText:(NSString*)disclosureText;
@end
