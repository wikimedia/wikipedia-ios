#import "WMFSettingsTableViewCell.h"
#import "UIColor+WMFHexColor.h"

@interface WMFSettingsTableViewCell ()

@property (strong, nonatomic) IBOutlet UIImageView* titleIcon;
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* disclosureLabel;
@property (strong, nonatomic) IBOutlet UIImageView* disclosureIcon;

@end

@implementation WMFSettingsTableViewCell

- (void)setTitle:(NSString*)title {
    _title               = title;
    self.titleLabel.text = title;
}

- (void)setIconName:(NSString*)iconName {
    _iconName            = iconName;
    self.titleIcon.image = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)setDisclosureText:(NSString*)disclosureText {
    _disclosureText           = disclosureText;
    self.disclosureLabel.text = disclosureText;
}

- (void)setIconColor:(UIColor*)iconColor {
    _iconColor                     = iconColor;
    self.titleIcon.backgroundColor = iconColor;
    self.titleIcon.tintColor       = [UIColor whiteColor];
}

- (void)setDisclosureType:(WMFSettingsMenuItemDisclosureType)disclosureType {
    _disclosureType = disclosureType;
    switch (disclosureType) {
        case WMFSettingsMenuItemDisclosureType_None:
            self.disclosureIcon.hidden   = YES;
            self.disclosureLabel.hidden  = YES;
            self.disclosureIcon.image    = nil;
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_ExternalLink:
            self.disclosureIcon.hidden   = NO;
            self.disclosureLabel.hidden  = YES;
            self.disclosureIcon.image    = [[UIImage imageNamed:@"mini-external"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_Switch:
            self.disclosureIcon.hidden   = YES;
            self.disclosureLabel.hidden  = YES;
            self.disclosureIcon.image    = nil;
            self.disclosureSwitch.hidden = NO;
            break;
        case WMFSettingsMenuItemDisclosureType_ViewController:
            self.disclosureIcon.hidden   = NO;
            self.disclosureLabel.hidden  = YES;
            self.disclosureIcon.image    = [[UIImage imageNamed:@"chevron-right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText:
            self.disclosureIcon.hidden   = NO;
            self.disclosureLabel.hidden  = NO;
            self.disclosureIcon.image    = [[UIImage imageNamed:@"chevron-right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.disclosureSwitch.hidden = YES;
            break;
        default:
            break;
    }
}

- (void)awakeFromNib {
    self.disclosureIcon.tintColor = [UIColor wmf_colorWithHex:0xC7C7C7 alpha:1.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    //HAX: reset the titleIcon's background color so it remains during the selection cell selection animation.
    self.iconColor = self.iconColor;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    //HAX: reset the titleIcon's background color so there's not a tiny flicker at the beginning of the selection cell selection animation.
    self.iconColor = self.iconColor;
}

@end
