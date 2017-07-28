#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "UIApplication+VisualTestUtils.h"

extern const BOOL WMFIsVisualTestRecordModeEnabled;

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

- (void)wmf_verifyMultilineLabelWithText:(id)stringOrAttributedString width:(CGFloat)width;

- (void)wmf_verifyCellWithIdentifier:(NSString *)identifier
                       fromTableView:(UITableView *)tableView
                               width:(CGFloat)width
                 configuredWithBlock:(void (^)(UITableViewCell *))block;

- (void)wmf_verifyView:(UIView *)view width:(CGFloat)width;

- (void)wmf_verifyViewAtWindowWidth:(UIView *)view;

@end
