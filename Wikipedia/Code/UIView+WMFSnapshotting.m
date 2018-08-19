#import "UIView+WMFSnapshotting.h"

@implementation UIView (WMFSnapshotting)

- (nullable UIImage *)wmf_snapshotImageAfterScreenUpdates:(BOOL)afterScreenUpdates {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:afterScreenUpdates];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (nullable UIImage *)wmf_snapshotImage {
    return [self wmf_snapshotImageAfterScreenUpdates:YES];
}

- (nullable UIImage *)wmf_stretchableSnapshotImageWithAlphaChannel {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *stretchableGradientImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    UIGraphicsEndImageContext();
    return stretchableGradientImage;
}

@end
