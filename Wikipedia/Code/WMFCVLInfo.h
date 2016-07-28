#import <Foundation/Foundation.h>

@class WMFCVLColumn;
@class WMFCVLSection;
@class WMFCVLAttributes;
@class WMFCVLInvalidationContext;
@class WMFColumnarCollectionViewLayout;
@class WMFCVLMetrics;
@protocol WMFColumnarCollectionViewLayoutDelegate;

/*!
 @class        WMFCVLInfo
 @abstract     A WMFCVLInfo is a snapshot of a WMFColumnarCollecitonViewLayout and the layout attributes of the items and supplementary views. It handles the layout and organization into colums based on the WMFCVLMetrics provided to it.
 @discussion   ...
 */
@interface WMFCVLInfo : NSObject <NSCopying>

@property (nonatomic, strong, nonnull, readonly) NSArray <WMFCVLColumn *> *columns;
@property (nonatomic, strong, nonnull, readonly) NSArray <WMFCVLSection *> *sections;

@property (nonatomic) CGSize boundsSize;
@property (nonatomic) CGSize contentSize;

/*!
 Initialize a new WMFCVLInfo with the given metrics.
 @param metrics     The metrics for the WMFCVLInfo
 @return A WMFCVLInfo with the given metrics
 */
- (nonnull instancetype)initWithMetrics:(nonnull WMFCVLMetrics *)metrics NS_DESIGNATED_INITIALIZER;

- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block;
- (void)enumerateColumnsWithBlock:(nonnull void(^)(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop))block;

- (nullable WMFCVLAttributes *)layoutAttributesForItemAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (nullable WMFCVLAttributes *)layoutAttributesForSupplementaryViewOfKind:(nonnull NSString *)elementKind atIndexPath:(nonnull NSIndexPath *)indexPath;

- (void)layoutForBoundsSize:(CGSize)size withDelegate:(nullable id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(nullable UICollectionView *)collectionView;

- (void)updateWithInvalidationContext:(nonnull WMFCVLInvalidationContext *)context delegate:(nullable id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(nullable UICollectionView *)collectionView;

- (void)updateContentSize;

@end