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

@end
