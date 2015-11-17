
#import "WMFEmptyNearbyTableViewCell.h"

@implementation WMFEmptyNearbyTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.emptyTextLabel.text = MWLocalizedString(@"home-nearby-nothing", nil);
    [self.reloadButton setTitle:MWLocalizedString(@"home-nearby-check-again", nil) forState:UIControlStateNormal];
}

@end
