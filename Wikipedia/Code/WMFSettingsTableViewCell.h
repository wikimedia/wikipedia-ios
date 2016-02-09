#import <UIKit/UIKit.h>
#import "SSBaseTableCell.h"
#import "WMFSettingsMenuItem.h"

@interface WMFSettingsTableViewCell : SSBaseTableCell

@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* iconName;

@property (nonatomic) WMFSettingsMenuItemDisclosureType disclosureType;

// Used only if disclosureType is WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText.
@property (strong, nonatomic) NSString* disclosureText;

@end
