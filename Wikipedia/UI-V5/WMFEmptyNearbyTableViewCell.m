
#import "WMFEmptyNearbyTableViewCell.h"

@implementation WMFEmptyNearbyTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.emptyTextLabel.text = MWLocalizedString(@"home-nearby-nothing", nil);
    [self.reloadButton setTitle:MWLocalizedString(@"home-nearby-check-again", nil) forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
