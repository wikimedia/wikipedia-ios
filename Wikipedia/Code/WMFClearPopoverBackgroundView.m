#import "WMFClearPopoverBackgroundView.h"

@interface WMFClearPopoverBackgroundView ()
@property (nonatomic, readwrite) CGFloat arrowOffset;
@property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection;
@end

@implementation WMFClearPopoverBackgroundView
@synthesize arrowOffset, arrowDirection;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.shadowColor = [[UIColor clearColor] CGColor];
    }
    return self;
}

+ (CGFloat)arrowBase {
    return 0;
}

+ (UIEdgeInsets)contentViewInsets {
    return UIEdgeInsetsZero;
}

+ (CGFloat)arrowHeight {
    return 0;
}

+ (BOOL)wantsDefaultContentAppearance {
    return NO;
}


@end

