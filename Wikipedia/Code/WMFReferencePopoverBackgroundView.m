#import "WMFReferencePopoverBackgroundView.h"
#import "WMFPopoverBackgroundView.h"
@import WMF.Swift;

@implementation WMFReferencePopoverBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.arrowColor = [UIColor wmf_referencePopoverBackground];
    }
    return self;
}

+ (BOOL)wantsDefaultContentAppearance {
    return YES;
}

@end
