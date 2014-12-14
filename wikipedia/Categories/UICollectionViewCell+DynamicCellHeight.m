//  Created by Monte Hurd on 12/13/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UICollectionViewCell+DynamicCellHeight.h"

@implementation UICollectionViewCell (DynamicCellHeight)

-(CGFloat)heightForSizingCellOfWidth:(CGFloat)width
{
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    self.bounds = CGRectMake(0.0f, 0.0f, width, CGRectGetHeight(self.bounds));
    [self setNeedsLayout];
    [self layoutIfNeeded];
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0f;
}

@end
