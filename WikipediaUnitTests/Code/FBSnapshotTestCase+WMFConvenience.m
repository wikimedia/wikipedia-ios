#import "FBSnapshotTestCase+WMFConvenience.h"
#import "XCTestCase+WMFVisualTestConvenience.h"
#import "UIView+VisualTestSizingUtils.h"


#if WMF_VISUAL_TEST_RECORD_MODE
const BOOL WMFIsVisualTestRecordModeEnabled = YES;
#else
const BOOL WMFIsVisualTestRecordModeEnabled = NO;
#endif

@implementation FBSnapshotTestCase (WMFConvenience)

- (void)wmf_verifyMultilineLabelWithText:(id)stringOrAttributedString width:(CGFloat)width {
    WMFSnapshotVerifyView([self wmf_getLabelSizedToFitWidth:width
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
                               width:(CGFloat)width
                 configuredWithBlock:(void (^)(UITableViewCell *))block {
    WMFSnapshotVerifyView([self wmf_getCellWithIdentifier:identifier
                                            fromTableView:tableView
                                          sizedToFitWidth:width
                                      configuredWithBlock:^(UITableViewCell *cell) {
                                          if (block) {
                                              block(cell);
                                          }
                                      }]);
}

- (void)wmf_verifyView:(UIView *)view width:(CGFloat)width {
    [view wmf_sizeToFitWidth:width];
    WMFSnapshotVerifyView(view);
}

- (void)wmf_verifyViewAtWindowWidth:(UIView *)view {
    UIWindow *window = view.window ?: [[UIApplication sharedApplication] keyWindow];
    [self wmf_verifyView:view width:window.bounds.size.width];
}

@end
