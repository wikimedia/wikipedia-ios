//
//  TGLStackedLayout.h
//  TGLStackedViewController
//
//  Created by Tim Gleue on 07.04.14.
//  Copyright (c) 2014 Tim Gleue ( http://gleue-interactive.com )
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <UIKit/UIKit.h>

@protocol TGLStackedLayoutDelegate;

@interface TGLStackedLayout : UICollectionViewLayout

@property (nonatomic, weak) id<TGLStackedLayoutDelegate> delegate;


/** Margins between collection view and items. Default is UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0) */
@property (assign, nonatomic) UIEdgeInsets layoutMargin;

/** Size of items if set to value not equal CGSizeZero.
 *
 * If set to CGSizeZero (default) item sizes are computed
 * from the collection view's bounds minus the margins defined
 * in property -layoutMargin.
 */
@property (assign, nonatomic) CGSize itemSize;

/** Amount to show of each stacked item. Default is 120.0 */
@property (assign, nonatomic) CGFloat topReveal;

/** Amount of compression/expansing when scrolling bounces. Default is 0.2 */
@property (assign, nonatomic) CGFloat bounceFactor;

/** Set to YES to ignore -topReveal and arrange items evenly in collection view's bounds, if items do not fill entire height. Default is NO. */
@property (assign, nonatomic, getter = isFillingHeight) BOOL fillHeight;

/** Set to YES to enable bouncing even when items do not fill entire height. Default is NO. */
@property (assign, nonatomic, getter = isAlwaysBouncing) BOOL alwaysBounce;

/** Use -contentOffset instead of collection view's actual content offset for next layout */
@property (assign, nonatomic) BOOL overwriteContentOffset;

/** Content offset value to replace actual value when -overwriteContentOffset is YES */
@property (assign, nonatomic) CGPoint contentOffset;

/** Index path of item currently being moved, and thus being hidden */
@property (strong, nonatomic) NSIndexPath *movingIndexPath;

@end



@protocol TGLStackedLayoutDelegate <UICollectionViewDelegateFlowLayout>

@optional

/** Check whether a given cell can be moved.
 *
 *
 * Implement this method to prevent items from
 * being dragged to another location.
 *
 * @param layout The layout requesting the information
 * @param indexPath Index path of item to be moved.
 *
 * @return YES if item can be moved (default); otherwise NO.
 */
- (BOOL)stackLayout:(TGLStackedLayout*)layout canMoveItemAtIndexPath:(NSIndexPath*)indexPath;

/** Retarget a item's proposed index path while being moved.
 *
 * Implement this method to modify an item's target location
 * while being dragged to another location, e.g. to prevent
 * it from being moved to certain locations.
 *
 * @param layout The layout requesting the information
 * @param sourceIndexPath Moving item's original index path.
 * @param proposedDestinationIndexPath The item's proposed index path during move.
 *
 * @return The item's desired index path. Return proposedDestinationIndexPath if
 *         it is suitable (default); or nil if item should not be moved.
 */
- (NSIndexPath*)stackLayout:(TGLStackedLayout*)layout targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

/** Move item in data source while dragging.
 *
 * Implement this method to update the collection
 * view's data source.
 *
 * @param layout The layout making the movee
 * @param fromIndexPath Original item indexPath
 * @param toIndexPath New item indexPath
 */
- (void)stackLayout:(TGLStackedLayout*)layout moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;


- (BOOL)stackLayout:(TGLStackedLayout*)layout canDeleteItemAtIndexPath:(NSIndexPath*)indexPath;

- (void)stackLayout:(TGLStackedLayout*)layout deleteItemAtIndexPath:(NSIndexPath*)indexPath;

@end
