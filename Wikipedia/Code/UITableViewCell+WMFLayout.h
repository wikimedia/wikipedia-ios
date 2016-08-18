#import <UIKit/UIKit.h>

@interface UITableViewCell (WMFLayout)

- (void)wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0;

@end

@interface UICollectionViewCell (WMFLayout)

- (void)wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0;

@end
