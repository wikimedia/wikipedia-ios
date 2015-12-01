
#import "UIView+WMFSnapshotting.h"

@implementation UIView (WMFSnapshotting)

- (UIImage*)wmf_snapshotImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIView*)wmf_addSnapshotToView:(UIView*)containerView afterScreenUpdates:(BOOL)afterUpdates {
    UIView* snapshot = [self snapshotViewAfterScreenUpdates:afterUpdates];
    snapshot.frame = [containerView convertRect:self.frame fromView:self.superview];
    [containerView addSubview:snapshot];
    return snapshot;
}

- (UIView*)wmf_addResizableSnapshotToView:(UIView*)containerView fromRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates withCapInsets:(UIEdgeInsets)capInsets {
    UIView* snapshot = [self resizableSnapshotViewFromRect:rect afterScreenUpdates:afterUpdates withCapInsets:UIEdgeInsetsZero];
    snapshot.frame = [containerView convertRect:rect fromView:self.superview];
    [containerView addSubview:snapshot];
    return snapshot;
}

@end
