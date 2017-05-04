#import "WMFColumnarCollectionViewLayout.h"
#import "WMFCVLInfo.h"
#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"
#import "WMFCVLAttributes.h"
#import "WMFCVLInvalidationContext.h"
#import "WMFCVLMetrics.h"

@interface WMFColumnarCollectionViewLayout ()

@property (nonatomic, readonly) id<WMFColumnarCollectionViewLayoutDelegate> delegate;
@property (nonatomic, strong) WMFCVLInfo *info;
@property (nonatomic, strong) WMFCVLMetrics *metrics;
@property (nonatomic, getter=isLayoutValid) BOOL layoutValid;
@property (nonatomic) NSInteger maxNewSection;
@property (nonatomic) CGFloat newSectionDeltaY;

@end

@implementation WMFColumnarCollectionViewLayout

#pragma mark - Classes

+ (Class)invalidationContextClass {
    return [WMFCVLInvalidationContext class];
}

+ (Class)layoutAttributesClass {
    return [WMFCVLAttributes class];
}

#pragma mark - Properties

- (id<WMFColumnarCollectionViewLayoutDelegate>)delegate {
    assert(self.collectionView.delegate == nil || [self.collectionView.delegate conformsToProtocol:@protocol(WMFColumnarCollectionViewLayoutDelegate)]);
    return (id<WMFColumnarCollectionViewLayoutDelegate>)self.collectionView.delegate;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    return [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
}

- (CGSize)collectionViewContentSize {
    return self.info.contentSize;
}

#pragma mark - Layout

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {

    NSMutableArray *attributesArray = [NSMutableArray array];

    [self.info enumerateSectionsWithBlock:^(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        if (CGRectIntersectsRect(section.frame, rect)) {
            [section enumerateLayoutAttributesWithBlock:^(WMFCVLAttributes *attributes, BOOL *stop) {
                if (CGRectIntersectsRect(attributes.frame, rect)) {
                    [attributesArray addObject:attributes];
                }
            }];
        }
    }];

    return attributesArray;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.info layoutAttributesForItemAtIndexPath:indexPath];
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return [self.info layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)prepareLayout {
    if (!self.isLayoutValid) {
        self.info = [[WMFCVLInfo alloc] init];
        self.metrics = [WMFCVLMetrics metricsWithBoundsSize:self.collectionView.bounds.size];
        [self.info layoutWithMetrics:self.metrics delegate:self.delegate collectionView:self.collectionView invalidationContext:nil];
        self.layoutValid = YES;
    }

    [super prepareLayout];
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset {
    return proposedContentOffset;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    return proposedContentOffset;
}

#pragma mark - Invalidation

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return newBounds.size.width != self.metrics.boundsSize.width;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    WMFCVLInvalidationContext *context = (WMFCVLInvalidationContext *)[super invalidationContextForBoundsChange:newBounds];
    context.boundsDidChange = YES;
    self.metrics = [WMFCVLMetrics metricsWithBoundsSize:newBounds.size];
    [self.info updateWithMetrics:self.metrics invalidationContext:context delegate:self.delegate collectionView:self.collectionView];
    return context;
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    return !CGRectEqualToRect(preferredAttributes.frame, originalAttributes.frame);
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    WMFCVLInvalidationContext *context = (WMFCVLInvalidationContext *)[super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
    if (context == nil) {
        context = [WMFCVLInvalidationContext new];
    }
    context.preferredLayoutAttributes = preferredAttributes;
    context.originalLayoutAttributes = originalAttributes;
    [self.info updateWithMetrics:self.metrics invalidationContext:context delegate:self.delegate collectionView:self.collectionView];
    return context;
}

- (void)invalidateLayoutWithContext:(WMFCVLInvalidationContext *)context {
    assert([context isKindOfClass:[WMFCVLInvalidationContext class]]);
    if (context.invalidateEverything || context.invalidateDataSourceCounts) {
        self.layoutValid = NO;
    }
    [super invalidateLayoutWithContext:context];
}

#pragma mark - Hit Detection

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesAtPoint:(CGPoint)point {
    __block UICollectionViewLayoutAttributes *attributesToReturn = nil;
    [self.info enumerateSectionsWithBlock:^(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        if (CGRectContainsPoint(section.frame, point)) {
            [section enumerateLayoutAttributesWithBlock:^(WMFCVLAttributes *attributes, BOOL *stop) {
                if (CGRectContainsPoint(attributes.frame, point)) {
                    attributesToReturn = attributes;
                    *stop = YES;
                }
            }];
        }
        *stop = attributesToReturn != nil;
    }];
    return attributesToReturn;
}

#pragma mark - Animation

- (void)prepareForCollectionViewUpdates:(NSArray<UICollectionViewUpdateItem *> *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    if (!self.slideInNewContentFromTheTop) {
        self.maxNewSection = -1;
        self.newSectionDeltaY = 0;
        return;
    }
    NSInteger maxSection = -1;
    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        if (updateItem.indexPathBeforeUpdate != nil || updateItem.indexPathAfterUpdate == nil) {
            continue;
        }
        if (updateItem.indexPathAfterUpdate.item != NSNotFound) {
            continue;
        }
        NSInteger section = updateItem.indexPathAfterUpdate.section;
        if (section != maxSection + 1) {
            continue;
        }
        maxSection = section;
    }
    if (maxSection >= self.info.sections.count) {
        self.maxNewSection = -1;
        return;
    }
    self.maxNewSection = maxSection;
    CGRect sectionFrame = self.info.sections[maxSection].frame;
    self.newSectionDeltaY = 0 - CGRectGetMaxY(sectionFrame);
}

- (void)adjustAttributesIfNecessary:(UICollectionViewLayoutAttributes *)attributes forItemOrElementAppearingAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section <= self.maxNewSection) {
        CGRect frame = attributes.frame;
        frame.origin.y = frame.origin.y + self.newSectionDeltaY;
        attributes.frame = frame;
        attributes.alpha = 1;
    }
}

- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    [self adjustAttributesIfNecessary:attributes forItemOrElementAppearingAtIndexPath:itemIndexPath];
    return attributes;
}

- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath {
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingSupplementaryElementOfKind:elementKind atIndexPath:elementIndexPath];
    [self adjustAttributesIfNecessary:attributes forItemOrElementAppearingAtIndexPath:elementIndexPath];
    return attributes;
}

- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingDecorationElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)decorationIndexPath {
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingDecorationElementOfKind:elementKind atIndexPath:decorationIndexPath];
    [self adjustAttributesIfNecessary:attributes forItemOrElementAppearingAtIndexPath:decorationIndexPath];
    return attributes;
}

@end
