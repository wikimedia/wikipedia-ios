#import "UIView+WMFFrameUtils.h"

FOUNDATION_EXPORT CGPoint WMFCenterOfCGSize(CGSize size) {
    return CGPointMake(size.width / 2.0, size.height / 2.0);
}

@implementation UIView (WMFFrameUtils)

- (void)wmf_setFrameOrigin:(CGPoint)origin {
    self.frame = (CGRect){.origin = origin, .size = self.frame.size};
}

- (void)wmf_setFrameSize:(CGSize)size {
    self.frame = (CGRect){.origin = self.frame.origin, .size = size};
}

- (void)wmf_insetWidth:(float)width height:(float)height {
    self.frame = CGRectInset(self.frame, width, height);
}

- (void)wmf_expandWidth:(float)width height:(float)height {
    [self wmf_insetWidth:-width height:-height];
}

- (void)wmf_centerInSuperview {
    self.center = WMFCenterOfCGSize(self.superview.frame.size);
}

@end
