//  Created by Monte Hurd on 8/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

/**
 *  Verify correct appearance of a given view.
 *
 *  Search all folder suffixes, use default naming conventions.
 *
 *  @param view The view to verify.
 */
#define WMFSnapshotVerifyView(view) FBSnapshotVerifyView((view), nil)

@interface FBSnapshotTestCase (WMFConvenience)

- (void)wmf_visuallyVerifyMultilineLabelWithText:(id)stringOrAttributedString;

- (void)wmf_visuallyVerifyCellWithIdentifier:(NSString*)identifier
                               fromTableView:(UITableView*)tableView
                         configuredWithBlock:(void (^)(UITableViewCell*))block;

- (void)wmf_verifyViewAtScreenWidth:(UIView*)view;

@end
