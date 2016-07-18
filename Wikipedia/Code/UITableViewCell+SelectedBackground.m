//  Created by Nirzar Pangarkar on 11/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UITableViewCell+SelectedBackground.h"

@implementation UITableViewCell (WMFCellSelectedBackground)

- (void)wmf_addSelectedBackgroundView {
    UIView* bgView = [[UIView alloc] init];
    bgView.backgroundColor      = [UIColor wmf_tapHighlightColor];
    self.selectedBackgroundView = bgView;
}

@end


@implementation UICollectionViewCell (WMFCellSelectedBackground)

- (void)wmf_addSelectedBackgroundView {
    UIView* bgView = [[UIView alloc] init];
    bgView.backgroundColor      = [UIColor wmf_tapHighlightColor];
    self.selectedBackgroundView = bgView;
}

@end