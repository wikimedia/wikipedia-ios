@import UIKit;

/*!
 @class        WMFCVLMetrics
 @abstract     WMFCVLMetrics represent the metrics used for a WMFColumnarCollectionViewLayout. The attributes of this object are for customizing the associated WMFColumnarCollectionViewLayout.
 @discussion   ...
 */
@interface WMFCVLMetrics : NSObject <NSCopying>

/*!
 The bounds size for the metrics
 */
@property (nonatomic, readonly) CGSize boundsSize;

/*!
 The adjusted content insets for the metrics
 */
@property (nonatomic, readonly) UIEdgeInsets adjustedContentInsets;

/*!
 The total number of columns
 */
@property (nonatomic, readonly) NSInteger numberOfColumns;

/*!
 The inset of the entire content (beyond the content inset)
 */
@property (nonatomic, readonly) UIEdgeInsets margins;

/*!
 The inset of each section's items (headers & footers not included)
 */
@property (nonatomic, readonly) UIEdgeInsets sectionInsets;

/*!
 The horizontal spacing between columns
 */
@property (nonatomic, readonly) CGFloat interColumnSpacing;

/*!
 The vertical spacing between sections within a column
 */
@property (nonatomic, readonly) CGFloat interSectionSpacing;

/*!
 The vertical spacing between items within a section
 */
@property (nonatomic, readonly) CGFloat interItemSpacing;

/*!
 The weight for each column's width - must add up to the total number of colums.
 @discussion @[ @1.25, @0.75, @1.0 ] is valid but @[ @1.25, @0.80, @1.0 ] is not
 */
@property (nonnull, nonatomic, copy, readonly) NSArray<NSNumber *> *columnWeights;

@property (nonatomic) BOOL shouldMatchColumnHeights;

+ (nonnull WMFCVLMetrics *)metricsWithBoundsSize:(CGSize)boundsSize adjustedContentInsets:(UIEdgeInsets)adjustedContentInsets layoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection;
+ (nonnull WMFCVLMetrics *)metricsWithBoundsSize:(CGSize)boundsSize adjustedContentInsets:(UIEdgeInsets)adjustedContentInsets firstColumnRatio:(CGFloat)firstColumnRatio secondColumnRatio:(CGFloat)secondColumnRatio collapseSectionSpacing:(BOOL)collapseSectionSpacing layoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection; // ratios should add up to 2
+ (nonnull WMFCVLMetrics *)singleColumnMetricsWithBoundsSize:(CGSize)boundsSize adjustedContentInsets:(UIEdgeInsets)adjustedContentInsets collapseSectionSpacing:(BOOL)collapseSectionSpacing;

@end
