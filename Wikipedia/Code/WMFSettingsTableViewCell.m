#import "WMFSettingsTableViewCell.h"

@interface WMFSettingsTableViewCell ()

@property (strong, nonatomic) IBOutlet UIImageView* titleIcon;
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;

@property (strong, nonatomic) IBOutlet UILabel* disclosureLabel;
@property (strong, nonatomic) IBOutlet UIImageView* disclosureIcon;
@property (strong, nonatomic) IBOutlet UISwitch* disclosureSwitch;

@end

@implementation WMFSettingsTableViewCell

-(void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

-(void)setIconName:(NSString *)iconName {
    _iconName = iconName;
    self.titleIcon.image = [UIImage imageNamed:iconName];
}

-(void)setDisclosureText:(NSString *)disclosureText {
    _disclosureText = disclosureText;
    self.disclosureLabel.text = disclosureText;
}

-(void)setDisclosureType:(WMFSettingsMenuItemDisclosureType)disclosureType {
    _disclosureType = disclosureType;
    switch (disclosureType) {
        case WMFSettingsMenuItemDisclosureType_ExternalLink:
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = [UIImage imageNamed:@"share-mini"];
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_Switch:
            self.disclosureIcon.hidden = YES;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = nil;
            self.disclosureSwitch.hidden = NO;
            break;
        case WMFSettingsMenuItemDisclosureType_ViewController:
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = [UIImage imageNamed:@"chevron-right"];
            self.disclosureSwitch.hidden = YES;
            break;
        case WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText:
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = NO;
            self.disclosureIcon.image = [UIImage imageNamed:@"chevron-right"];
            self.disclosureSwitch.hidden = YES;
            break;
        default:
            break;
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
