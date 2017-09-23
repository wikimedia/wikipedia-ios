#import "UIScrollView+WMFAdjustmentBehavior.h"
#import "NSObject+WMFMethodSwizzling.h"

@implementation UIScrollView (WMFAdjustmentBehavior)

+ (void)load {
    if ([self class] == [UIScrollView class]) {
        if (@available(iOS 11, *)) {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                [self wmf_swizzleOriginalSelector:@selector(initWithFrame:)
                               toSwizzledSelector:@selector(wmf_initWithFrame:)];
                [self wmf_swizzleOriginalSelector:@selector(initWithCoder:)
                               toSwizzledSelector:@selector(wmf_initWithCoder:)];
            });
        }
    }
}

- (instancetype)wmf_initWithFrame:(CGRect)frame {
    [self wmf_initWithFrame:frame];
    if (self) {
        if (@available(iOS 11, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

- (nullable instancetype)wmf_initWithCoder:(NSCoder *)aDecoder {
    [self wmf_initWithCoder:aDecoder];
    if (self) {
        if (@available(iOS 11, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

@end
