#import "FBSnapshotTestCase+WMFConvenience.h"
#import "XCTestCase+WMFVisualTestConvenience.h"
#import "UIView+VisualTestSizingUtils.h"

#if WMF_VISUAL_TEST_RECORD_MODE
const BOOL WMFIsVisualTestRecordModeEnabled = YES;
#else
const BOOL WMFIsVisualTestRecordModeEnabled = NO;
#endif

@implementation FBSnapshotTestCase (WMFConvenience)

- (void)wmf_verifyMultilineLabelWithText:(id)stringOrAttributedString {
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    WMFSnapshotVerifyViewForOSAndWritingDirection([self wmf_getLabelSizedToFitWidth:width
                                                                configuredWithBlock:^(UILabel *label) {
                                                                    if ([stringOrAttributedString isKindOfClass:[NSString class]]) {
                                                                        label.text = stringOrAttributedString;
                                                                    } else if ([stringOrAttributedString isKindOfClass:[NSAttributedString class]]) {
                                                                        label.attributedText = stringOrAttributedString;
                                                                    }
                                                                }]);
}

- (void)wmf_verifyCellWithIdentifier:(NSString *)identifier
                       fromTableView:(UITableView *)tableView
                 configuredWithBlock:(void (^)(UITableViewCell *))block {
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    WMFSnapshotVerifyViewForOSAndWritingDirection([self wmf_getCellWithIdentifier:identifier
                                                                    fromTableView:tableView
                                                                  sizedToFitWidth:width
                                                              configuredWithBlock:^(UITableViewCell *cell) {
                                                                  if (block) {
                                                                      block(cell);
                                                                  }
                                                              }]);
}

- (void)wmf_verifyView:(UIView *)view {
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    [view wmf_sizeToFitWidth:width];
    WMFSnapshotVerifyViewForOSAndWritingDirection(view);
}

@end
