@import UIKit.UITableView;

@interface UITableView (DynamicCellHeight)

// UITableView's "tableView:heightForRowAtIndexPath:" lets the table know how
// tall a cell needs to be. This method lets us easily determine the exact
// height via an offscreen sizing cell.
- (CGFloat)heightForSizingCell:(UITableViewCell *)cell;

@end
