//  Created by Monte Hurd on 8/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "UIApplication+VisualTestUtils.h"

/**
 *  @function WMFSnapshotVerifyView
 *
 *  Verify correct appearance of a given view.
 *
 *  Search all folder suffixes, use default naming conventions.
 *
 *  @param view The view to verify.
 */
#define WMFSnapshotVerifyView(view) FBSnapshotVerifyView((view), nil)

/**
 *  @function WMFSnapshotVerifyViewForOSAndWritingDirection
 *
 *  Compares @c view with a reference image matching the current OS version & application writing direction (e.g.
 *  "testLaysOutProperly_9.2_RTL@2x.png").
 *
 *  @param view The view to verify.
 */
#define WMFSnapshotVerifyViewForOSAndWritingDirection(view) \
    FBSnapshotVerifyView((view), [[UIApplication sharedApplication] wmf_systemVersionAndWritingDirection]);

@interface FBSnapshotTestCase (WMFConvenience)

- (void)wmf_visuallyVerifyMultilineLabelWithText:(id)stringOrAttributedString;

- (void)wmf_visuallyVerifyCellWithIdentifier:(NSString*)identifier
                               fromTableView:(UITableView*)tableView
                         configuredWithBlock:(void (^)(UITableViewCell*))block;

- (void)wmf_verifyViewAtScreenWidth:(UIView*)view;

@end
