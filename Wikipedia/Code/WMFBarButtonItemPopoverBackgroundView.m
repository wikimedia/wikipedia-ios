#import "WMFBarButtonItemPopoverBackgroundView.h"
#import "WMFPopoverBackgroundView.h"
@import WMF.Swift;

@implementation WMFBarButtonItemPopoverBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.arrowColor = [UIColor wmf_barButtonItemPopoverMessageBackground];
    }
    return self;
}

@end
