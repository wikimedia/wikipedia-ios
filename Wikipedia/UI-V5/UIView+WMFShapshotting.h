
#import <UIKit/UIKit.h>

@interface UIView (WMFShapshotting)

- (UIView*)wmf_snapshotAfterScreenUpdates:(BOOL)afterUpdates andAddToContainerView:(UIView*)containerView;
- (UIView*)wmf_resizableSnapshotViewFromRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates andAddToContainerView:(UIView*)containerView;


@end
