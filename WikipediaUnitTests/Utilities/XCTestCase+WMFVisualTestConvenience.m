//  Created by Monte Hurd on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "XCTestCase+WMFVisualTestConvenience.h"

@implementation XCTestCase (WMFVisualTestConvenience)

- (UILabel*)wmf_getLabelConfiguredWithBlock:(void (^)(UILabel*))block {
    UILabel* label = [[UILabel alloc] init];
    label.lineBreakMode   = NSLineBreakByWordWrapping;
    label.numberOfLines   = 0;
    label.backgroundColor = [UIColor whiteColor];

    if (block) {
        block(label);
    }

    CGSize preHeightAdjustmentSize = (CGSize){320, 100};

    CGSize heightAdjustedSize = [label systemLayoutSizeFittingSize:preHeightAdjustmentSize
                                     withHorizontalFittingPriority:UILayoutPriorityRequired
                                           verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    label.frame = (CGRect){CGPointZero, heightAdjustedSize};
    return label;
}

- (UITableViewCell*)wmf_getCellWithIdentifier:(NSString*)identifier
                                fromTableView:(UITableView*)tableView
                          configuredWithBlock:(void (^)(UITableViewCell*))block {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (block) {
        block(cell);
    }

    CGSize preHeightAdjustmentSize = (CGSize){320, 100};

    CGSize heightAdjustedSize = [cell.contentView systemLayoutSizeFittingSize:preHeightAdjustmentSize
                                                withHorizontalFittingPriority:UILayoutPriorityRequired
                                                      verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    CGRect adjustedRect = (CGRect){CGPointZero, heightAdjustedSize};
    cell.contentView.frame = adjustedRect;
    cell.frame             = adjustedRect;

    return cell;
}

@end
