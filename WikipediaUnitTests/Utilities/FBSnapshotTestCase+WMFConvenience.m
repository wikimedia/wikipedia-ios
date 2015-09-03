//  Created by Monte Hurd on 8/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "FBSnapshotTestCase+WMFConvenience.h"
#import "XCTestCase+WMFVisualTestConvenience.h"
#import "UIView+VisualTestSizingUtils.h"

/**
 *  Verify correct appearance of a given view.
 *
 *  This is required to work around a bug in FBSnapshotTestCase that will mix up the suffix of the reference image folder.
 *
 *  @param view The view to verify.
 */
#define WMFSnapshotVerifyView(view) FBSnapshotVerifyViewWithOptions((view), nil, [NSSet setWithObject:@"_64"], 0)

@implementation FBSnapshotTestCase (WMFConvenience)

- (void)wmf_visuallyVerifyMultilineLabelWithText:(id)stringOrAttributedString {
    WMFSnapshotVerifyView([self wmf_getLabelConfiguredWithBlock:^(UILabel* label){
        if ([stringOrAttributedString isKindOfClass:[NSString class]]) {
            label.text = stringOrAttributedString;
        } else if ([stringOrAttributedString isKindOfClass:[NSAttributedString class]]) {
            label.attributedText = stringOrAttributedString;
        }
    }]);
}

- (void)wmf_visuallyVerifyCellWithIdentifier:(NSString*)identifier
                               fromTableView:(UITableView*)tableView
                         configuredWithBlock:(void (^)(UITableViewCell*))block {
    WMFSnapshotVerifyView([self wmf_getCellWithIdentifier:identifier fromTableView:tableView configuredWithBlock:^(UITableViewCell* cell){
        if (block) {
            block(cell);
        }
    }]);
}

- (void)wmf_verifyViewAtScreenWidth:(UIView*)view {
    [view wmf_sizeToFitScreenWidth];
    WMFSnapshotVerifyView(view);
}

@end
