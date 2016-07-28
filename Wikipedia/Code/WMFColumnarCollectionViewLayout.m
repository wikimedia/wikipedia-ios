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

@property (nonatomic, strong) WMFCVLInfo *oldInfo;
@property (nonatomic, strong) WMFCVLInfo *info;
@property (nonatomic, strong) WMFCVLInfo *nextInfo;

@property (nonatomic) BOOL needsLayout;

@end

@implementation WMFColumnarCollectionViewLayout

- (nonnull instancetype)initWithMetrics:(nonnull WMFCVLMetrics *)metrics {
    self = [super init];
    if (self) {
        self.metrics = metrics;
        self.needsLayout = YES;
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

#pragma mark - Properties

- (id <WMFColumnarCollectionViewLayoutDelegate>)delegate {
    assert(self.collectionView.delegate == nil || [self.collectionView.delegate conformsToProtocol:@protocol(WMFColumnarCollectionViewLayoutDelegate)]);
    return (id <WMFColumnarCollectionViewLayoutDelegate>)self.collectionView.delegate;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    return [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
}

+ (Class)invalidationContextClass {
    return [WMFCVLInvalidationContext class];
}

+ (Class)layoutAttributesClass {
    return [WMFCVLAttributes class];
}

- (CGSize)collectionViewContentSize {
    return self.info.contentSize;
}

- (void)layoutForBoundsSize:(CGSize)size {
    if (self.delegate == nil) {
        return;
    }
    self.oldInfo = self.info;
    self.info = [[WMFCVLInfo alloc] initWithMetrics:self.metrics];
    [self.info layoutForBoundsSize:size withDelegate:self.delegate collectionView:self.collectionView];
}

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

#pragma mark - Invalidation

- (void)prepareLayout {
    if (self.needsLayout) {
        [self layoutForBoundsSize:self.collectionView.bounds.size];
    } else if (self.nextInfo) {
        self.oldInfo = self.info;
        self.info = self.nextInfo;
    }
    self.needsLayout = NO;
    self.nextInfo = nil;
    [super prepareLayout];
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return newBounds.size.width != self.info.boundsSize.width;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    WMFCVLInvalidationContext *invalidationContext = (WMFCVLInvalidationContext *)[super invalidationContextForBoundsChange:newBounds];
    invalidationContext.boundsDidChange = YES;
    invalidationContext.newBounds = newBounds;
    [self updateLayoutForInvalidationContext:invalidationContext];
    return invalidationContext;
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    return !CGRectEqualToRect(preferredAttributes.frame, originalAttributes.frame);
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    WMFCVLInvalidationContext *invalidationContext = (WMFCVLInvalidationContext *)[super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
    if (invalidationContext == nil) {
        invalidationContext = [WMFCVLInvalidationContext new];
    }
    invalidationContext.preferredLayoutAttributes = preferredAttributes;
    invalidationContext.originalLayoutAttributes = originalAttributes;
    [self updateLayoutForInvalidationContext:invalidationContext];
    return invalidationContext;
}

- (void)updateLayoutForInvalidationContext:(WMFCVLInvalidationContext *)context {
    self.needsLayout = [self.info updateWithInvalidationContext:context delegate:self.delegate collectionView:self.collectionView];
}

- (void)invalidateLayoutWithContext:(WMFCVLInvalidationContext *)context {
    assert([context isKindOfClass:[WMFCVLInvalidationContext class]]);
    if (context.invalidateEverything || context.invalidateDataSourceCounts) {
        self.needsLayout = YES;
    }
    [super invalidateLayoutWithContext:context];
}
@end

