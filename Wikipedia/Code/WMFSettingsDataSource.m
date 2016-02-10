#import "WMFSettingsDataSource.h"
#import "WMFSettingsTableViewCell.h"
#import "WMFSettingsMenuItem.h"
#import "UIColor+WMFHexColor.h"
#import "SessionSingleton.h"
#import "MWKSite.h"

@implementation WMFSettingsDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cellClass          = [WMFSettingsTableViewCell class];
        self.cellConfigureBlock = ^(WMFSettingsTableViewCell* cell, WMFSettingsMenuItem* menuItem, UITableView* tableView, NSIndexPath* indexPath) {
            cell.title          = menuItem.title;
            cell.iconColor      = menuItem.iconColor;
            cell.iconName       = menuItem.iconName;
            cell.disclosureType = menuItem.disclosureType;
            cell.disclosureText = menuItem.disclosureText;
            cell.isSwitchOn     = menuItem.isSwitchOn;
        };
        self.tableActionBlock = ^BOOL (SSCellActionType action, UITableView* tableView, NSIndexPath* indexPath) {
            return NO;
        };
    }
    return self;
}

- (void)rebuildSections {
    CGPoint tableContentOffset = self.tableView.contentOffset;

    [self removeAllSections];
    NSArray<SSSection*>* allSections =
    @[
      [self section_1],
      [self section_2],
      [self section_3],
      [self section_4],
      [self section_5],
      [self section_6],
      [self section_7]
      ];

    [UIView setAnimationsEnabled:NO];

    [self.tableView beginUpdates];
    [self insertSections:allSections atIndexes:[NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, allSections.count)]];
    [self.tableView setContentOffset:tableContentOffset];
    [self.tableView endUpdates];

    
    [UIView setAnimationsEnabled:YES];
}

WMFSettingsMenuItem* (^ makeItem)(WMFSettingsMenuItemType, NSString*, NSString*, NSInteger, WMFSettingsMenuItemDisclosureType, NSString*, BOOL) = ^WMFSettingsMenuItem*(WMFSettingsMenuItemType type, NSString* title, NSString* iconName, NSInteger iconColor, WMFSettingsMenuItemDisclosureType disclosureType, NSString* disclosureText, BOOL isSwitchOn) {
    return [[WMFSettingsMenuItem alloc] initWithType:type
                                               title:title
                                            iconName:iconName
                                           iconColor:[UIColor wmf_colorWithHex:iconColor alpha:1.0]
                                      disclosureType:disclosureType
                                      disclosureText:disclosureText
                                          isSwitchOn:isSwitchOn];
};

-(SSSection*)section_1 {
    NSString* userName  = [SessionSingleton sharedInstance].keychainCredentials.userName;
    NSString *loginString = (userName) ? [MWLocalizedString(@"main-menu-account-title-logged-in", nil) stringByReplacingOccurrencesOfString:@"$1" withString:userName] : MWLocalizedString(@"main-menu-account-login", nil);
    
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       makeItem(WMFSettingsMenuItemType_Login, loginString, @"settings-user", userName ? 0xFF8E2B : 0x9CA1A7, WMFSettingsMenuItemDisclosureType_ViewController, @"", NO),
       makeItem(WMFSettingsMenuItemType_Support, MWLocalizedString(@"settings-support", nil), @"settings-support", 0xFF1B33, WMFSettingsMenuItemDisclosureType_ExternalLink, @"", NO)
       ]];
    section.header = @"";
    section.footer = @"";
    return section;
}

-(SSSection*)section_2 {
    NSString* languageCode = [SessionSingleton sharedInstance].searchSite.language;
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       makeItem(WMFSettingsMenuItemType_SearchLanguage, MWLocalizedString(@"settings-project", nil), @"settings-project", 0x1F95DE, WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText, [languageCode uppercaseString], NO)
       ]];
    section.header = @"";
    section.footer = @"";
    return section;
}

-(SSSection*)section_3 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       makeItem(WMFSettingsMenuItemType_PrivacyPolicy, MWLocalizedString(@"main-menu-privacy-policy", nil), @"settings-privacy", 0x884FDC, WMFSettingsMenuItemDisclosureType_ViewController, @"", NO),
       makeItem(WMFSettingsMenuItemType_Terms, MWLocalizedString(@"main-menu-terms-of-use", nil), @"settings-terms", 0x99A1A7, WMFSettingsMenuItemDisclosureType_ViewController, @"", NO),
       makeItem(WMFSettingsMenuItemType_SendUsageReports, MWLocalizedString(@"preference_title_eventlogging_opt_in", nil), @"settings-analytics", 0x95D15A, WMFSettingsMenuItemDisclosureType_Switch, @"", [SessionSingleton sharedInstance].shouldSendUsageReports)
       ]];
    section.header = MWLocalizedString(@"main-menu-heading-legal", nil);
    section.footer = MWLocalizedString(@"preference_summary_eventlogging_opt_in", nil);
    return section;
}

-(SSSection*)section_4 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       makeItem(WMFSettingsMenuItemType_ZeroWarnWhenLeaving, MWLocalizedString(@"zero-warn-when-leaving", nil), @"settings-zero", 0x1F95DE,WMFSettingsMenuItemDisclosureType_Switch, @"", [SessionSingleton sharedInstance].zeroConfigState.warnWhenLeaving),
       makeItem(WMFSettingsMenuItemType_ZeroFAQ, MWLocalizedString(@"main-menu-zero-faq", nil), @"settings-faq", 0x99A1A7, WMFSettingsMenuItemDisclosureType_ExternalLink, @"", NO)
       ]];
    section.header = MWLocalizedString(@"main-menu-heading-zero", nil);
    section.footer = @"";
    return section;
}

-(SSSection*)section_5 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       makeItem(WMFSettingsMenuItemType_RateApp, MWLocalizedString(@"main-menu-rate-app", nil), @"settings-rate", 0xFEA13D, WMFSettingsMenuItemDisclosureType_ViewController, @"", NO),
       makeItem(WMFSettingsMenuItemType_SendFeedback, MWLocalizedString(@"main-menu-send-feedback", nil), @"settings-feedback", 0x00B18D, WMFSettingsMenuItemDisclosureType_ViewController, @"", NO)
       ]];
    section.header = @"";
    section.footer = @"";
    return section;
}

-(SSSection*)section_6 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       makeItem(WMFSettingsMenuItemType_About, MWLocalizedString(@"main-menu-about", nil), @"settings-about", 0x000000, WMFSettingsMenuItemDisclosureType_ViewController, @"", NO),
       makeItem(WMFSettingsMenuItemType_FAQ, MWLocalizedString(@"main-menu-faq", nil), @"settings-faq", 0x99A1A7, WMFSettingsMenuItemDisclosureType_ExternalLink, @"", NO)
       ]];
    section.header = @"";
    section.footer = @"";
    return section;
}

-(SSSection*)section_7 {
    SSSection* section =
    [SSSection sectionWithItems:
     @[
       makeItem(WMFSettingsMenuItemType_DebugCrash, MWLocalizedString(@"main-menu-debug-crash", nil), @"settings-crash", 0xFF1B33, WMFSettingsMenuItemDisclosureType_None, @"", NO),
       makeItem(WMFSettingsMenuItemType_DevSettings, MWLocalizedString(@"main-menu-debug-tweaks", nil), @"settings-dev", 0x1F95DE,WMFSettingsMenuItemDisclosureType_ViewController, @"", NO)
       ]];
    section.header = MWLocalizedString(@"main-menu-heading-debug", nil);
    section.footer = @"";
    return section;
}

@end
