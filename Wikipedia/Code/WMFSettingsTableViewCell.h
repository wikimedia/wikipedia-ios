#import "WMFSettingsMenuItem.h"
@import WMF.Swift;
@class WMFSettingsTableViewCell;

@protocol WMFSettingsTableViewCellDelegate <NSObject>

- (void)settingsTableViewCell:(WMFSettingsTableViewCell *)settingsTableViewCell didToggleDisclosureSwitch:(UISwitch *)sender;

@end

@interface WMFSettingsTableViewCell : UITableViewCell <WMFThemeable>

@property (nonatomic) WMFSettingsMenuItemDisclosureType disclosureType;

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *subtitle;
@property (strong, nonatomic) NSString *iconName;

/// Shown only if disclosureType is WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
@property (strong, nonatomic) NSString *disclosureText;

/// Shown only if disclosureType is WMFSettingsMenuItemDisclosureType_Switch
@property (strong, nonatomic) IBOutlet UISwitch *disclosureSwitch;

@property (strong, nonatomic) UIColor *iconColor;
@property (strong, nonatomic) UIColor *iconBackgroundColor;

@property (nonatomic, weak) id<WMFSettingsTableViewCellDelegate> delegate;
- (void)configure:(WMFSettingsMenuItemDisclosureType)disclosureType disclosureText:(NSString *)disclosureText title:(NSString *)title subtitle:(NSString *)subtitle iconName:(NSString *)iconName isSwitchOn:(BOOL)isSwitchOn iconColor:(UIColor *)iconColor iconBackgroundColor:(UIColor *)iconBackgroundColor controlTag:(NSInteger)controlTag theme:(WMFTheme *)theme;

- (void)configure:(WMFSettingsMenuItemDisclosureType)disclosureType disclosureText:(NSString *)disclosureText title:(NSString *)title subtitle:(NSString *)subtitle iconName:(NSString *)iconName iconColor:(UIColor *)iconColor iconBackgroundColor:(UIColor *)iconBackgroundColor theme:(WMFTheme *)theme;

- (void)applyTheme:(WMFTheme *)theme;

@end
