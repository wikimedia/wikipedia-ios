//
//  WMFPagingCollectionViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * View controller which displays "pages" of content using a collection view.
 */
@interface WMFPageCollectionViewController : UICollectionViewController

@property (nonatomic) NSUInteger currentPage;

- (void)setCurrentPage:(NSUInteger)currentPage animated:(BOOL)animated;

/**
 * Flag which dictates whether or not the current `currentPage` has been applied.
 *
 * Check this whenever doing work while view size is transitioning or device is rotating, as
 * `WMFPageCollectionViewController` will set/reset this flag as necessary to ensure `currentPage` is maintained
 * through a transition.
 */
@property (nonatomic) BOOL didApplyCurrentPage;

@end
