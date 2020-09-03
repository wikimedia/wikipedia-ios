@import UIKit;
@class WMFCVLColumn;
@class WMFCVLSection;
@class WMFCVLAttributes;
@class WMFCVLInvalidationContext;

/*!
 @class        WMFCVLSectionColumn
 @abstract     A WMFCVLSection represents a column within a section of a WMFColumnarCollectionViewLayout. It handles adjusting the size and offset of items within the section.
 @discussion   ...
 */
@interface WMFCVLSectionColumn : NSObject

@property (nonatomic, readonly) NSInteger index;
@property (nonatomic) NSInteger columnIndex;
@property (nonatomic) CGRect frame;
@property (nonatomic) BOOL needsToRecalculateEstimatedLayout;

@property (nonatomic, strong, readonly, nonnull) NSArray<WMFCVLAttributes *> *items;

+ (nonnull WMFCVLSection *)sectionWithIndex:(NSInteger)index;

- (BOOL)addOrUpdateItemAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame, WMFCVLAttributes *_Nonnull layoutAttributes))frameProvider;
- (BOOL)addOrUpdateHeaderAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame, WMFCVLAttributes *_Nonnull layoutAttributes))frameProvider;
- (BOOL)addOrUpdateFooterAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame, WMFCVLAttributes *_Nonnull layoutAttributes))frameProvider;

- (void)enumerateLayoutAttributesWithBlock:(nonnull void (^)(WMFCVLAttributes *_Nonnull layoutAttributes, BOOL *_Nonnull stop))block;

- (void)offsetByDeltaY:(CGFloat)deltaY withInvalidationContext:(nonnull UICollectionViewLayoutInvalidationContext *)invalidationContext;

- (CGFloat)setSize:(CGSize)size forItemAtIndex:(NSInteger)index invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (CGFloat)setSize:(CGSize)size forHeaderAtIndex:(NSInteger)headerIndex invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (CGFloat)setSize:(CGSize)size forFooterAtIndex:(NSInteger)footerIndex invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;

- (void)trimItemsToCount:(NSInteger)count;

@end
