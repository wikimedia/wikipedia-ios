//
//  UICollectionViewFlowLayout+AttributeUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/26/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UICollectionViewFlowLayout+AttributeUtils.h"
#import <BlocksKit/BlocksKit.h>

@implementation UICollectionViewFlowLayout (AttributeUtils)

- (NSIndexPath*)wmf_indexPathClosestToContentOffset {
    return [[[self wmf_layoutAttributesByDistanceToPoint:self.collectionView.contentOffset] firstObject] indexPath];
}

- (NSArray*)wmf_sortAttributesByLeadingEdgeDistance:(NSArray*)attributes toPoint:(CGPoint)point {
    return [attributes sortedArrayUsingComparator:^NSComparisonResult (UICollectionViewLayoutAttributes* attr1,
                                                                       UICollectionViewLayoutAttributes* attr2) {
        float leadingEdgeDistance1 = fabsf(point.x - attr1.frame.origin.x);
        float leadingEdgeDistance2 = fabsf(point.x - attr2.frame.origin.x);
        return leadingEdgeDistance1 - leadingEdgeDistance2;
    }];
}

- (NSArray*)wmf_layoutAttributesByDistanceToPoint:(CGPoint)point {
    return [self wmf_sortAttributesByLeadingEdgeDistance:[self wmf_layoutAttributesForVisibleIndexPaths] toPoint:point];
}

- (NSArray*)wmf_layoutAttributesForVisibleIndexPaths {
    return [self.collectionView.indexPathsForVisibleItems bk_map:^(NSIndexPath* path) {
        return [self layoutAttributesForItemAtIndexPath:path];
    }];
}

@end
