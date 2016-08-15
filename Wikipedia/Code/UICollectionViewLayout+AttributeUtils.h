//
//  UICollectionViewLayout+AttributeUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/26/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Utilities for getting layout attributes and index paths for items in a flow layout.
 * @warning Most of these methods were naively implemented and only support layouts configured with a horizontal
 *          scrolling direction.
 */
@interface UICollectionViewLayout (AttributeUtils)

/// The @c NSIndexPath for the item closest to the current @c contentOffset.x of the receiver's @c collectionView.
- (NSIndexPath *)wmf_indexPathHorizontallyClosestToContentOffset;

/**
 * Sort an array of @c UICollectionViewLayoutAttribute objects by their distance to @c point in ascending order.
 * @param attributes The @c UICollectionViewLayoutAttributes objects to sort.
 * @param point      A point within the @c contentSize of the receiver's @c collectionView.
 * @return A sorted version of the given @c attributes array.
 */
- (NSArray *)wmf_sortAttributesByLeadingEdgeDistance:(NSArray *)attributes toPoint:(CGPoint)point;

/**
 * Get an array of the currently visible items' attributes, sorted by distance to @c point in ascending order.
 * @param point A point within the @c contentSize of the receiver's @c collectionView.
 * @return An array of @c UICollectionViewLayoutAttributes.
 * @see -wmf_sortAttributesByLeadingEdgeDistance:toPoint
 */
- (NSArray *)wmf_layoutAttributesByDistanceToPoint:(CGPoint)point;

/**
 * Map the receiver's <code>collectionView.indexPathsForVisibleItems</code> into an array of their layout attributes.
 * @return An array of @c UICollectionViewLayoutAttributes.
 */
- (NSArray *)wmf_layoutAttributesForVisibleIndexPaths;

@end
