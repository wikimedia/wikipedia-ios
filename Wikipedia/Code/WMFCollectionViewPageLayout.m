//
//  WMFCollectionViewPageLayout.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFCollectionViewPageLayout.h"
#import "UICollectionViewFlowLayout+WMFItemSizeThatFits.h"

@implementation WMFCollectionViewPageLayout

- (void)prepareLayout {
    [super prepareLayout];
    [self wmf_itemSizeToFit];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return [super shouldInvalidateLayoutForBoundsChange:newBounds] || !CGSizeEqualToSize(newBounds.size, self.itemSize);
}

@end
