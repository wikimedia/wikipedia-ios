//
//  SSBaseCollectionCell.h
//  SSDataSources
//
//  Created by Jonathan Hersh on 6/24/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

/**
 * Generic collection view cell. Subclass me!
 * Override `configureCell` to do one-time setup at cell creation, like creating subviews.
 * You probably don't need to override `identifier`.
 */

#import <UIKit/UIKit.h>

@interface SSBaseCollectionCell : UICollectionViewCell

/**
 * Dequeues a collection cell from collectionView, or if there are no cells of the
 * receiver's type in the queue, creates a new cell and calls -configureCell.
 */
+ (instancetype) cellForCollectionView:(UICollectionView *)collectionView
                             indexPath:(NSIndexPath *)indexPath;

/**
 *  Cell's identifier. You probably don't need to override this.
 *
 *  @return an identifier for this cell class
 */
+ (NSString *) identifier;

/**
 *  Override me in your subclass!
 */
- (void) configureCell;

@end
