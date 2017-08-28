#import "WMFSettingsMenuItem.h"
@import WMF.Swift;

@interface WMFSettingsTableViewCell : UITableViewCell <WMFThemeable>

@property (nonatomic) WMFSettingsMenuItemDisclosureType disclosureType;

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *iconName;

/// Shown only if disclosureType is WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
@property (strong, nonatomic) NSString *disclosureText;

/// Shown only if disclosureType is WMFSettingsMenuItemDisclosureType_Switch
@property (strong, nonatomic) IBOutlet UISwitch *disclosureSwitch;

@property (strong, nonatomic) UIColor *iconColor;
@property (strong, nonatomic) UIColor *iconBackgroundColor;

@end
