//
//  SSBaseCollectionReusableView.h
//  SSDataSources
//
//  Created by Jonathan Hersh on 8/8/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

/**
 * A simple base collection reusable view. Subclass me if necessary.
 */

#import <UIKit/UIKit.h>

@interface SSBaseCollectionReusableView : UICollectionReusableView

/**
 * Dequeues a supplementary view from collectionView, or if there are no cells of the
 * receiver's type in the queue, creates a new view.
 */
+ (instancetype) supplementaryViewForCollectionView:(UICollectionView *)cv
                                               kind:(NSString *)kind
                                          indexPath:(NSIndexPath *)indexPath;

/**
 *  Identifier for this supplementary view. You probably don't need to override this.
 *
 *  @return identifier for this view
 */
+ (NSString *) identifier;

@end
