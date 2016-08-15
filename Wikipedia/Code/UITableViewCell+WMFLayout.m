#import "UITableViewCell+WMFLayout.h"
#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"

@implementation UITableViewCell (WMFLayout)

- (void)wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0 {
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        [self layoutIfNeeded];
    }
}

@end

@implementation UICollectionViewCell (WMFLayout)

- (void)wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0 {
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        [self layoutIfNeeded];
    }
}

@end
