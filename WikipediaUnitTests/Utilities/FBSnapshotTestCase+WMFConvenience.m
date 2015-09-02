//  Created by Monte Hurd on 8/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "FBSnapshotTestCase+WMFConvenience.h"
#import "XCTestCase+WMFVisualTestConvenience.h"

@implementation FBSnapshotTestCase (WMFConvenience)

- (void)wmf_visuallyVerifyMultilineLabelWithText:(id)stringOrAttributedString {
    FBSnapshotVerifyViewWithOptions([self wmf_getLabelConfiguredWithBlock:^(UILabel* label){
        if ([stringOrAttributedString isKindOfClass:[NSString class]]) {
            label.text = stringOrAttributedString;
        } else if ([stringOrAttributedString isKindOfClass:[NSAttributedString class]]) {
            label.attributedText = stringOrAttributedString;
        }
    }], nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)wmf_visuallyVerifyCellWithIdentifier:(NSString*)identifier
                               fromTableView:(UITableView*)tableView
                         configuredWithBlock:(void (^)(UITableViewCell*))block {
    FBSnapshotVerifyViewWithOptions([self wmf_getCellWithIdentifier:identifier fromTableView:tableView configuredWithBlock:^(UITableViewCell* cell){
        if (block) {
            block(cell);
        }
    }], nil, [NSSet setWithObject:@"_64"], 0);
}

@end
