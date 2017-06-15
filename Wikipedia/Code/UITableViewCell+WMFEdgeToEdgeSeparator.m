#import <WMF/UITableViewCell+WMFEdgeToEdgeSeparator.h>

@implementation UITableViewCell (WMFEdgeToEdgeSeparator)

- (void)wmf_makeCellDividerBeEdgeToEdge {
    self.layoutMargins = UIEdgeInsetsZero;
    self.separatorInset = UIEdgeInsetsZero;
    [self setPreservesSuperviewLayoutMargins:NO];
}

@end

@implementation UICollectionViewCell (WMFEdgeToEdgeSeparator)

- (void)wmf_makeCellDividerBeEdgeToEdge {
    self.layoutMargins = UIEdgeInsetsZero;
    [self setPreservesSuperviewLayoutMargins:NO];
}

@end
