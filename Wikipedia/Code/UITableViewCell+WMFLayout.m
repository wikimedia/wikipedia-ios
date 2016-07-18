//  Created by Monte Hurd on 11/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

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
