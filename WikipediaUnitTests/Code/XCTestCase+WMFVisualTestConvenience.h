#import <XCTest/XCTest.h>

@interface XCTestCase (WMFVisualTestConvenience)

/**
 *  Get UILabel configured to 320 width and dynamic height based on length of text being shown.
 *  Useful for quick FBSnapshotTestCase test cases.
 *
 *  @param block This block is passed the label for easy configuration.
 *
 *  @return UILabel
 */
- (UILabel *)wmf_getLabelSizedToFitWidth:(CGFloat)width
                     configuredWithBlock:(void (^)(UILabel *))block;

/**
 *  Get UITableViewCell configured to 320 width and dynamic height based on autolayout properties of its subviews.
 *  Useful for quick FBSnapshotTestCase test cases.
 *
 *  @param block This block is passed the cell for easy configuration.
 *
 *  @return UITableViewCell
 */
- (UITableViewCell *)wmf_getCellWithIdentifier:(NSString *)identifier
                                 fromTableView:(UITableView *)tableView
                               sizedToFitWidth:(CGFloat)width
                           configuredWithBlock:(void (^)(UITableViewCell *))block;

@end
