#import <UIKit/UIKit.h>
#import <SSDataSources/SSBaseTableCell.h>
#import "WMFSettingsMenuItem.h"

@interface WMFSettingsTableViewCell : SSBaseTableCell

@property (nonatomic) WMFSettingsMenuItemDisclosureType disclosureType;

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *iconName;
@property (strong, nonatomic) UIColor *iconColor;

/// Shown only if disclosureType is WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
@property (strong, nonatomic) NSString *disclosureText;

/// Shown only if disclosureType is WMFSettingsMenuItemDisclosureType_Switch
@property (strong, nonatomic) IBOutlet UISwitch *disclosureSwitch;

@end
