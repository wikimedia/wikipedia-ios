#import "UITableViewCell+SelectedBackground.h"

@implementation UITableViewCell (WMFCellSelectedBackground)

- (void)wmf_addSelectedBackgroundView {
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = [UIColor wmf_tapHighlight];
    self.selectedBackgroundView = bgView;
}

@end

@implementation UICollectionViewCell (WMFCellSelectedBackground)

- (void)wmf_addSelectedBackgroundView {
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = [UIColor wmf_tapHighlight];
    self.selectedBackgroundView = bgView;
}

@end
