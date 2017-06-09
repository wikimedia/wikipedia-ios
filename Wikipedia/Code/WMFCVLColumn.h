@import UIKit;

@class WMFCVLSection;
@class WMFCVLInvalidationContext;
@class WMFCVLInfo;

/*!
 @class        WMFCVLColumn
 @abstract     A WMFCVLColumn is a snapshot of a column within a WMFColumnarCollecitonViewLayout. It handles adjustment of the size of items and supplementary views within it.
 @discussion   ...
 */
@interface WMFCVLColumn : NSObject <NSCopying>

@property (nonatomic) NSInteger index;
@property (nonatomic) CGRect frame;
@property (nonatomic, weak, nullable) WMFCVLInfo *info;
@property (nonatomic, readonly) NSInteger sectionCount;

@property (nonatomic, readonly, nullable) WMFCVLSection *lastSection;

- (void)addSection:(nonnull WMFCVLSection *)section;
- (void)removeSection:(nonnull WMFCVLSection *)section;
- (void)removeSectionsWithSectionIndexesInRange:(NSRange)range;

- (BOOL)containsSectionWithSectionIndex:(NSInteger)sectionIndex; //Index of the section in the data source, not based on the order in which it appears in this column
- (void)enumerateSectionsWithBlock:(nonnull void (^)(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop))block;

- (void)setSize:(CGSize)size forItemAtIndexPath:(nonnull NSIndexPath *)indexPath invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (void)setSize:(CGSize)size forHeaderAtIndexPath:(nonnull NSIndexPath *)indexPath invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (void)setSize:(CGSize)size forFooterAtIndexPath:(nonnull NSIndexPath *)indexPath invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;

- (void)updateHeightWithDelta:(CGFloat)deltaH;

@end
