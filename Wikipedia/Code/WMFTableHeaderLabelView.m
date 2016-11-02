
#import "WMFTableHeaderLabelView.h"

@implementation WMFTableHeaderLabelView

- (void)awakeFromNib{
    [super awakeFromNib];
    self.textLabel.textColor = [UIColor wmf_nearbyDescriptionColor];
}
@end
