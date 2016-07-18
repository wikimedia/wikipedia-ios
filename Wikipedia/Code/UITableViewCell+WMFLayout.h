//  Created by Monte Hurd on 11/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UITableViewCell (WMFLayout)

- (void)wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0;

@end

@interface UICollectionViewCell (WMFLayout)

- (void)wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0;

@end
