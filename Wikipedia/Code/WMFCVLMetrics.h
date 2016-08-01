#import <Foundation/Foundation.h>

/*!
 @class        WMFCVLMetrics
 @abstract     WMFCVLMetrics represent the metrics used for a WMFColumnarCollectionViewLayout. The attributes of this object are for customizing the associated WMFColumnarCollectionViewLayout.
 @discussion   ...
 */
@interface WMFCVLMetrics : NSObject <NSCopying>

/*!
 The total number of columns
 */
@property (nonatomic) NSInteger numberOfColumns;

/*!
 The inset of the entire content
 */
@property (nonatomic) UIEdgeInsets contentInsets;

/*!
 The inset of each section's items (headers & footers not included)
 */
@property (nonatomic) UIEdgeInsets sectionInsets;

/*!
 The horizontal spacing between columns
 */
@property (nonatomic) CGFloat interColumnSpacing;

/*!
 The vertical spacing between sections within a column
 */
@property (nonatomic) CGFloat interSectionSpacing;

/*!
 The vertical spacing between items within a section
 */
@property (nonatomic) CGFloat interItemSpacing;

/*!
 The weight for each column's width - must add up to the total number of colums.
 @discussion @[ @1.25, @0.75, @1.0 ] is valid but @[ @1.25, @0.80, @1.0 ] is not
 */
@property (nonatomic, copy) NSArray *columnWeights;

+ (WMFCVLMetrics *)defaultMetrics;

@end
