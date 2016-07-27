#import <Foundation/Foundation.h>

@class WMFCVLSection;
@class WMFCVLInvalidationContext;
@class WMFCVLInfo;

@interface WMFCVLColumn : NSObject <NSCopying>

@property (nonatomic) NSInteger index;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic, weak, nullable) WMFCVLInfo *info;

- (void)addSection:(nonnull WMFCVLSection *)section;
- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block;

- (void)setSize:(CGSize)size forItemAtIndexPath:(nonnull NSIndexPath *)indexPath invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (void)setSize:(CGSize)size forHeaderAtIndexPath:(nonnull NSIndexPath *)indexPath invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (void)setSize:(CGSize)size forFooterAtIndexPath:(nonnull NSIndexPath *)indexPath invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;

@end
