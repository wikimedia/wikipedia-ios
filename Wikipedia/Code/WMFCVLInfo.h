@import UIKit.UICollectionView;
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

@property (nonatomic, strong, nonnull, readonly) NSArray<WMFCVLColumn *> *columns;
@property (nonatomic, strong, nonnull, readonly) NSArray<WMFCVLSection *> *sections;

@property (nonatomic) CGSize contentSize;

- (void)enumerateSectionsWithBlock:(nonnull void (^)(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop))block;
- (void)enumerateColumnsWithBlock:(nonnull void (^)(WMFCVLColumn *_Nonnull column, NSUInteger idx, BOOL *_Nonnull stop))block;

- (nonnull WMFCVLAttributes *)layoutAttributesForItemAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (nonnull WMFCVLAttributes *)layoutAttributesForSupplementaryViewOfKind:(nonnull NSString *)elementKind atIndexPath:(nonnull NSIndexPath *)indexPath;

- (void)layoutWithMetrics:(nonnull WMFCVLMetrics *)metrics delegate:(nullable id<WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(nullable UICollectionView *)collectionView invalidationContext:(nullable WMFCVLInvalidationContext *)context;

- (void)updateWithMetrics:(nonnull WMFCVLMetrics *)metrics invalidationContext:(nullable WMFCVLInvalidationContext *)context delegate:(nullable id<WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(nullable UICollectionView *)collectionView;

@end
