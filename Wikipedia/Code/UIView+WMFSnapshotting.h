
#import <UIKit/UIKit.h>

@interface UIView (WMFSnapshotting)

- (UIImage*)wmf_snapshotImage;

- (UIView*)wmf_addSnapshotToView:(UIView*)containerView afterScreenUpdates:(BOOL)afterUpdates;
- (UIView*)wmf_addResizableSnapshotToView:(UIView*)containerView fromRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates withCapInsets:(UIEdgeInsets)capInsets;

@end
