//  Created by Monte Hurd on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "XCTestCase+WMFLabelConvenience.h"

@implementation XCTestCase (WMFLabelConvenience)

- (UILabel*)wmf_getLabelConfiguredWithBlock:(void (^)(UILabel*))block {
    UILabel* label = [[UILabel alloc] init];
    label.lineBreakMode   = NSLineBreakByWordWrapping;
    label.numberOfLines   = 0;
    label.backgroundColor = [UIColor whiteColor];

    if (block) {
        block(label);
    }

    CGSize preHeightAdjustmentSize = (CGSize){320, 100};

    CGSize heightAdjustedSize = [label systemLayoutSizeFittingSize:preHeightAdjustmentSize withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    label.frame = (CGRect){CGPointZero, heightAdjustedSize};
    return label;
}

@end
