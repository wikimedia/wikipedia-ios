#import "WMFColumnarCollectionViewLayout.h"
#import "WMFCVLInfo.h"
#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"
#import "WMFCVLAttributes.h"
#import "WMFCVLInvalidationContext.h"
#import "WMFCVLMetrics.h"

@interface WMFColumnarCollectionViewLayout ()

@property (nonatomic, readonly) id <WMFColumnarCollectionViewLayoutDelegate> delegate;
@property (nonatomic, strong) WMFCVLMetrics *metrics;
@property (nonatomic, strong) WMFCVLInfo *info;

@end

@implementation WMFColumnarCollectionViewLayout

- (nonnull instancetype)initWithMetrics:(nonnull WMFCVLMetrics *)metrics {
    self = [super init];
    if (self) {
        self.metrics = metrics;
    }
    return self;
}

- (instancetype)init {
    return [self initWithMetrics:[WMFCVLMetrics defaultMetrics]];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        if (!self.metrics) {
            self.metrics = [WMFCVLMetrics defaultMetrics];
        }
    }
    return self;
}

#pragma mark - Classes

+ (Class)invalidationContextClass {
    return [WMFCVLInvalidationContext class];
}

+ (Class)layoutAttributesClass {
    return [WMFCVLAttributes class];
}

#pragma mark - Properties

- (id <WMFColumnarCollectionViewLayoutDelegate>)delegate {
    assert(self.collectionView.delegate == nil || [self.collectionView.delegate conformsToProtocol:@protocol(WMFColumnarCollectionViewLayoutDelegate)]);
    return (id <WMFColumnarCollectionViewLayoutDelegate>)self.collectionView.delegate;
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
    
    [self.info enumerateSectionsWithBlock:^(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
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

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)resetLayout {
    self.info = [[WMFCVLInfo alloc] initWithMetrics:self.metrics];
    [self.info updateWithInvalidationContext:nil delegate:self.delegate collectionView:self.collectionView];
}

- (void)prepareLayout {
    if (self.info == nil) {
        [self resetLayout];
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
    return newBounds.size.width != self.info.boundsSize.width;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    WMFCVLInvalidationContext *context = (WMFCVLInvalidationContext *)[super invalidationContextForBoundsChange:newBounds];
    context.boundsDidChange = YES;
    context.newBounds = newBounds;
    [self.info updateWithInvalidationContext:context delegate:self.delegate collectionView:self.collectionView];
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
    [self.info updateWithInvalidationContext:context delegate:self.delegate collectionView:self.collectionView];
    return context;
}

- (void)invalidateLayoutWithContext:(WMFCVLInvalidationContext *)context {
    assert([context isKindOfClass:[WMFCVLInvalidationContext class]]);
    if (context.invalidateEverything) {
        [self resetLayout];
    } else if (context.invalidateDataSourceCounts) {
        [self.info updateWithInvalidationContext:context delegate:self.delegate collectionView:self.collectionView];
    }
    [super invalidateLayoutWithContext:context];
}

@end

