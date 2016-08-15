#import "XCTestCase+WMFVisualTestConvenience.h"
#import "UIView+VisualTestSizingUtils.h"

@implementation XCTestCase (WMFVisualTestConvenience)

- (UILabel *)wmf_getLabelSizedToFitWidth:(CGFloat)width
                     configuredWithBlock:(void (^)(UILabel *))block {
    UILabel *label = [[UILabel alloc] init];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor whiteColor];

    if (block) {
        block(label);
    }

    [label wmf_sizeToFitWidth:width];

    return label;
}

- (UITableViewCell *)wmf_getCellWithIdentifier:(NSString *)identifier
                                 fromTableView:(UITableView *)tableView
                               sizedToFitWidth:(CGFloat)width
                           configuredWithBlock:(void (^)(UITableViewCell *))block {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (block) {
        block(cell);
    }

    [cell wmf_sizeToFitWidth:width];

    return cell;
}

@end
