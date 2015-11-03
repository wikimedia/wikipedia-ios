//
//  WMFMainPageCell.m
//  Wikipedia
//
//  Created by Corey Floyd on 11/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFMainPageCell.h"

@interface WMFMainPageCell ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* leadingPaddingConstriant;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* trailingPaddingConstraint;

@end

@implementation WMFMainPageCell

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    CGFloat const preferredMaxLayoutWidth = layoutAttributes.size.width - (self.leadingPaddingConstriant.constant + self.trailingPaddingConstraint.constant);

    self.mainPageTitle.preferredMaxLayoutWidth = preferredMaxLayoutWidth;

    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];

    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
    return preferredAttributes;
}

@end
