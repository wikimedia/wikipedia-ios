#import <Foundation/Foundation.h>

@class WMFCVLColumn;
@class WMFCVLAttributes;
@class WMFCVLInvalidationContext;

@interface WMFCVLSection : NSObject

@property (nonatomic, readonly) NSInteger index;
@property (nonatomic) CGRect frame;
@property (nonatomic, weak, nullable) WMFCVLColumn *column;

@property (nonatomic, strong, readonly, nonnull) NSArray <WMFCVLAttributes *> *headers;
@property (nonatomic, strong, readonly, nonnull) NSArray <WMFCVLAttributes *> *footers;
@property (nonatomic, strong, readonly, nonnull) NSArray <WMFCVLAttributes *> *items;

+ (nonnull WMFCVLSection *)sectionWithIndex:(NSInteger)index;

- (void)addItem:(nonnull WMFCVLAttributes *)item;
- (void)addHeader:(nonnull WMFCVLAttributes *)header;
- (void)addFooter:(nonnull WMFCVLAttributes *)footer;

- (void)enumerateLayoutAttributesWithBlock:(nonnull void(^)(WMFCVLAttributes * _Nonnull layoutAttributes, BOOL * _Nonnull stop))block;

- (void)offsetByDeltaY:(CGFloat)deltaY withInvalidationContext:(nonnull UICollectionViewLayoutInvalidationContext *)invalidationContext;

- (CGFloat)setSize:(CGSize)size forItemAtIndex:(NSInteger)index invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (CGFloat)setSize:(CGSize)size forHeaderAtIndex:(NSInteger)headerIndex invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (CGFloat)setSize:(CGSize)size forFooterAtIndex:(NSInteger)footerIndex invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;

@end