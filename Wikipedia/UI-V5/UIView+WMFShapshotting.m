
#import "UIView+WMFShapshotting.h"

@implementation UIView (WMFShapshotting)

- (UIView*)wmf_snapshotAfterScreenUpdates:(BOOL)afterUpdates andAddToContainerView:(UIView*)containerView {
    UIView* snapshot = [self snapshotViewAfterScreenUpdates:afterUpdates];
    snapshot.frame = [containerView convertRect:self.frame fromView:self.superview];
    [containerView addSubview:snapshot];
    return snapshot;
}

- (UIView*)wmf_resizableSnapshotViewFromRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates andAddToContainerView:(UIView*)containerView {
    UIView* snapshot = [self resizableSnapshotViewFromRect:rect afterScreenUpdates:afterUpdates withCapInsets:UIEdgeInsetsZero];
    snapshot.frame = [containerView convertRect:rect fromView:self.superview];
    [containerView addSubview:snapshot];
    return snapshot;
}

@end
