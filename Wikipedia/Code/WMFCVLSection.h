#import <Foundation/Foundation.h>

@class WMFCVLColumn;
@class WMFCVLAttributes;
@class WMFCVLInvalidationContext;

/*!
 @class        WMFCVLSection
 @abstract     A WMFCVLSection represents a section within a column of a WMFColumnarCollectionViewLayout. It handles adjusting the size and offset of items within the section.
 @discussion   ...
 */
@interface WMFCVLSection : NSObject

@property (nonatomic, readonly) NSInteger index;
@property (nonatomic) CGRect frame;

@property (nonatomic, strong, readonly, nonnull) NSArray <WMFCVLAttributes *> *headers;
@property (nonatomic, strong, readonly, nonnull) NSArray <WMFCVLAttributes *> *footers;
@property (nonatomic, strong, readonly, nonnull) NSArray <WMFCVLAttributes *> *items;

+ (nonnull WMFCVLSection *)sectionWithIndex:(NSInteger)index;

- (BOOL)addOrUpdateItemAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame))frameProvider;
- (BOOL)addOrUpdateHeaderAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame))frameProvider;
- (BOOL)addOrUpdateFooterAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame))frameProvider;

- (void)enumerateLayoutAttributesWithBlock:(nonnull void(^)(WMFCVLAttributes * _Nonnull layoutAttributes, BOOL * _Nonnull stop))block;

- (void)offsetByDeltaY:(CGFloat)deltaY withInvalidationContext:(nonnull UICollectionViewLayoutInvalidationContext *)invalidationContext;

- (CGFloat)setSize:(CGSize)size forItemAtIndex:(NSInteger)index invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (CGFloat)setSize:(CGSize)size forHeaderAtIndex:(NSInteger)headerIndex invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (CGFloat)setSize:(CGSize)size forFooterAtIndex:(NSInteger)footerIndex invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;

- (void)trimItemsToCount:(NSInteger)count;

@end