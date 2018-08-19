@import UIKit;

@interface UIView (WMFSnapshotting)

- (nullable UIImage *)wmf_snapshotImageAfterScreenUpdates:(BOOL)afterScreenUpdates;
- (nullable UIImage *)wmf_snapshotImage;
- (nullable UIImage *)wmf_stretchableSnapshotImageWithAlphaChannel;

@end
