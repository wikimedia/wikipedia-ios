#import "WMFArticleFooterMenuCell.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@implementation WMFArticleFooterMenuCell

+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleSubtitle;
}

- (void)configureCell {
    [self wmf_makeCellDividerBeEdgeToEdge];
    self.textLabel.numberOfLines       = 0;
    self.textLabel.lineBreakMode       = NSLineBreakByWordWrapping;
    self.imageView.contentMode         = UIViewContentModeCenter;
    self.imageView.tintColor           = [UIColor grayColor];
    self.detailTextLabel.textColor     = [UIColor grayColor];
    self.detailTextLabel.numberOfLines = 0;
    self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
}

@end
