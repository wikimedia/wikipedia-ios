#import "WMFReferencePopoverBackgroundView.h"
#import "WMFPopoverBackgroundView.h"
#import "UIColor+WMFStyle.h"

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
