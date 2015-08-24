//
//  SelfSizingWaterfallCollectionViewLayout.h
//  SelfSizingWaterfallCollectionViewLayout
//
//  Created by Adam Waite on 01/10/2014.
//  Copyright (c) 2014 adamjwaite.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 SelfSizingWaterfallCollectionViewLayout is a concrete layout object that organizes items into a grid of variable columnns with optional header and footer views for each section. The items in the collection view flow from one row or column to the next, with each item being placed beneath the shortest column in the section (as if you're winning at Tetris upside-down). Collection view items can be the same size or different sizes and should implement `preferredLayoutAttributesFittingAttributes:` to provide final layout information.
 */
@interface SelfSizingWaterfallCollectionViewLayout : UICollectionViewLayout

/**
 The margins used to lay out content in a section. Default: UIEdgeInsetsZero.
 */
@property (nonatomic) UIEdgeInsets sectionInset;

/**
 The number of columns in the layout. Default: 2.
 */
@property (nonatomic) NSUInteger numberOfColumns;

/**
 The minimum spacing to use between items in the same row. Default: 8.0f;
 */
@property (nonatomic) CGFloat minimumInteritemSpacing;

/**
 The minimum spacing to use between lines of items in the layout. Default: 8.0f;
 */
@property (nonatomic) CGFloat minimumLineSpacing;

/**
 The size for collection view headers. Default: CGSizeZero;
 
 @note A value returned by `preferredLayoutAttributesFittingAttributes:` should determine the final value but it appears Apple haven't implemented self sizing for supplementaries...? Meaning that this value is final unless the delegate implements `collectionView:layout:referenceSizeForHeaderInSection:`
 */
@property (nonatomic) CGSize headerReferenceSize;

/**
 The size for collection view footers. Default: CGSizeZero;
 
 @note A value returned by `preferredLayoutAttributesFittingAttributes:` should determine the final value but it appears Apple haven't implemented self sizing for supplementaries...? Meaning that this value is final unless the delegate implements `collectionView:layout:referenceSizeForFooterInSection:`
 */
@property (nonatomic) CGSize footerReferenceSize;

/**
 An estimate for an item's height for use in a preliminary layout. A value returned by `preferredLayoutAttributesFittingAttributes:` in a UICollectionViewCell will take precedence over this value. Default: 200.0f.
 */
@property (nonatomic) CGFloat estimatedItemHeight;

@end


/**
 An object conforming to SelfSizingWaterfallCollectionViewLayoutDelegate may provide layout information for a SelfSizingWaterfallCollectionViewLayout instance. All of the methods in this protocol are optional. If you do not implement a particular method, the layout uses values in its own properties for the appropriate layout information.
 
 The self sizing waterfall layout object expects the collection view’s delegate object to adopt this protocol. Therefore, implement this protocol on object assigned to your collection view’s delegate property.
 */
@protocol SelfSizingWaterfallCollectionViewLayoutDelegate <UICollectionViewDelegate>

@optional

/**
 Asks the delegate for the margins to apply to content in the specified section.
 
 @param collectionView       The collection view object displaying the waterfall layout.
 @param collectionViewLayout The layout object requesting the information.
 @param section              The section in which the layout information is needed.
 
 @return The margins to apply to items in the section.
 */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;

/**
 Asks the delegate how many columns a section should contain.
 
 @param collectionView       The collection view object displaying the waterfall layout.
 @param collectionViewLayout The layout object requesting the information.
 @param section              The section in which the layout information is needed.
 
 @return The number of columns for the section.
 */
- (NSUInteger)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout numberOfColumnsInSection:(NSUInteger)section;

/**
 Asks the delegate for the horizontal spacing between columns.
 
 @param collectionView       The collection view object displaying the waterfall layout.
 @param collectionViewLayout The layout object requesting the information.
 @param section              The section in which the layout information is needed.
 
 @return Asks the delegate for the horizontal spacing between columns.
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;

/**
 Asks the delegate for the vertical spacing between successive items in a column of a section.
 
 @param collectionView       The collection view object displaying the waterfall layout.
 @param collectionViewLayout The layout object requesting the information.
 @param section              The section in which the layout information is needed.
 
 @return Vertical spacing between successive items in a column of a section.
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section;

/**
 Asks the delegate for the size of the header view in the specified section.

 @param collectionView       The collection view object displaying the waterfall layout.
 @param collectionViewLayout The layout object requesting the information.
 @param section              The section in which the layout information is needed.
 
 @note A value returned by `preferredLayoutAttributesFittingAttributes:` would have ideally determined the final layout but self sizing hasn't hasn't been implemented by Apple for supplementary views as far as I can tell, so this value is final...
 
 @return The size of the header view in the specified section
 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSUInteger)section;

/**
 Asks the delegate for the size of the footer view in the specified section.
 
 @param collectionView       The collection view object displaying the waterfall layout.
 @param collectionViewLayout The layout object requesting the information.
 @param section              The section in which the layout information is needed.
 
 @note A value returned by `preferredLayoutAttributesFittingAttributes:` would have ideally determined the final layout but self sizing hasn't hasn't been implemented by Apple for supplementary views as far as I can tell, so this value is final...
 
 @return The size of the footer view in the specified section
 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSUInteger)section;

/**
 Asks the delegate for an estimate of the height of the specified item’s cell for a preliminary layout pass.
 
 @note For apps requiring iOS7 compatibility, use this method to return a final value rather than an estimate.
 
 @param collectionView       The collection view object displaying the waterfall layout.
 @param collectionViewLayout The layout object requesting the information.
 @param indexPath            The indexPath in which the layout information is needed.
 
 @return An estimate of the height for the cell at the indexPath.
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath;

@end
