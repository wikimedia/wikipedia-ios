
#import "UIView+WMFShapshotting.h"

@implementation UIView (WMFShapshotting)

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
