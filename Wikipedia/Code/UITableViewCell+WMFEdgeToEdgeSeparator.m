//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@implementation UITableViewCell (WMFEdgeToEdgeSeparator)

- (void)wmf_makeCellDividerBeEdgeToEdge {
    self.layoutMargins  = UIEdgeInsetsZero;
    self.separatorInset = UIEdgeInsetsZero;
    [self setPreservesSuperviewLayoutMargins:NO];
}

@end


@implementation UICollectionViewCell (WMFEdgeToEdgeSeparator)

- (void)wmf_makeCellDividerBeEdgeToEdge {
    self.layoutMargins  = UIEdgeInsetsZero;
    [self setPreservesSuperviewLayoutMargins:NO];
}

@end
