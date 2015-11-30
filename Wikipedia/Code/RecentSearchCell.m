//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RecentSearchCell.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@implementation RecentSearchCell

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self wmf_makeCellDividerBeEdgeToEdge];
    }
    return self;
}

@end
