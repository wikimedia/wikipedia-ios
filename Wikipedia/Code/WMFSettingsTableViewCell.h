#import <UIKit/UIKit.h>
#import "SSBaseTableCell.h"
#import "WMFSettingsMenuItem.h"

@interface WMFSettingsTableViewCell : SSBaseTableCell

@property (nonatomic) WMFSettingsMenuItemDisclosureType disclosureType;

@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* iconName;
@property (strong, nonatomic) UIColor* iconColor;

// "disclosureText" is used only if disclosureType is WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText.
@property (strong, nonatomic) NSString* disclosureText;

// "isSwitchOn" is used only if disclosureType is WMFSettingsMenuItemDisclosureType_Switch.
@property (nonatomic) BOOL isSwitchOn;

@end
