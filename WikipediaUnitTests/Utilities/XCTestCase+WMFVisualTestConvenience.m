//  Created by Monte Hurd on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "XCTestCase+WMFVisualTestConvenience.h"
#import "UIView+VisualTestSizingUtils.h"

@implementation XCTestCase (WMFVisualTestConvenience)

- (UILabel*)wmf_getLabelConfiguredWithBlock:(void (^)(UILabel*))block {
    UILabel* label = [[UILabel alloc] init];
    label.lineBreakMode   = NSLineBreakByWordWrapping;
    label.numberOfLines   = 0;
    label.backgroundColor = [UIColor whiteColor];

    if (block) {
        block(label);
    }

    [label wmf_sizeToFitScreenWidth];

    return label;
}

- (UITableViewCell*)wmf_getCellWithIdentifier:(NSString*)identifier
                                fromTableView:(UITableView*)tableView
                          configuredWithBlock:(void (^)(UITableViewCell*))block {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (block) {
        block(cell);
    }

    [cell wmf_sizeToFitScreenWidth];

    return cell;
}

@end
