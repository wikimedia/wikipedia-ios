#import "WMFReferencePopoverBackgroundView.h"
#import "WMFPopoverBackgroundView.h"

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
