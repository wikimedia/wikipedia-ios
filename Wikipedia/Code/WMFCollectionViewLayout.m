#import "WMFCollectionViewLayout.h"

@interface WMFCollectionViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext
@property (nonatomic, copy) UICollectionViewLayoutAttributes *originalLayoutAttributes;
@property (nonatomic, copy) UICollectionViewLayoutAttributes *preferredLayoutAttributes;
@end

@interface WMFCollectionViewLayout () {
    CGFloat *_estimatedSectionHeights;
    CGFloat *_estimatedColumnHeights;
}

@property (nonatomic, readonly) id <WMFCollectionViewLayoutDelegate> delegate;
@property (nonatomic) CGFloat interColumnSpacing;
@property (nonatomic) CGFloat interSectionSpacing;
@property (nonatomic) CGFloat interItemSpacing;
@property (nonatomic) CGFloat estimatedHeaderHeight;
@property (nonatomic) CGFloat estimatedFooterHeight;
@property (nonatomic) CGFloat estimatedItemHeight;
@property (nonatomic) CGFloat estimatedHeight;

@property (nonatomic) NSMutableArray *estimatedHeaderAttributes;
@property (nonatomic) NSMutableArray *estimatedFooterAttributes;
@property (nonatomic) NSMutableArray *estimatedItemAttributes;

@property (nonatomic) CGFloat columnWidth;
@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfSections;
@property (nonatomic, strong) NSMutableDictionary *estimatedLayoutAttributes;

@property (nonatomic, getter=shouldReestimateLayout) BOOL reestimateLayout;

@end

@implementation WMFCollectionViewLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.numberOfColumns = 1;
    self.interColumnSpacing = 1;
    self.interItemSpacing = 1;
    self.interSectionSpacing = 0;
}


#pragma mark - Properties

- (id <WMFCollectionViewLayoutDelegate>)delegate {
    assert(self.collectionView.delegate == nil || [self.collectionView.delegate conformsToProtocol:@protocol(WMFCollectionViewLayoutDelegate)]);
    return (id <WMFCollectionViewLayoutDelegate>)self.collectionView.delegate;
}

- (NSUInteger)numberOfSections {
    return [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section {
    return [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
}

+ (Class)invalidationContextClass {
    return [WMFCollectionViewLayoutInvalidationContext class];
}

- (void)prepareLayout {
    [super prepareLayout];
    [self estimateLayout];
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.bounds.size.width, self.estimatedHeight);
}

- (void)estimateLayout {
    if (!self.shouldReestimateLayout) {
        return;
    }
    self.estimatedHeaderAttributes = [NSMutableArray array];
    self.estimatedFooterAttributes = [NSMutableArray array];
    self.estimatedItemAttributes = [NSMutableArray array];
    self.columnWidth = floor(self.collectionView.bounds.size.width/self.numberOfColumns);
    
    free(_estimatedSectionHeights);
    _estimatedSectionHeights = malloc(self.numberOfSections*sizeof(CGFloat));
    
    free(_estimatedColumnHeights);
    _estimatedColumnHeights = malloc(self.numberOfColumns*sizeof(CGFloat));
    
    CGFloat columnWidth = self.columnWidth;
    CGFloat currentColumnHeight = 0;
    NSUInteger currentColumnIndex = 0;
    
    for (NSUInteger section = 0; section < self.numberOfSections; section++) {
        CGFloat x = currentColumnIndex * self.columnWidth;
        CGFloat y = currentColumnHeight;
        
        CGFloat sectionHeight = 0;
        
        CGFloat headerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForHeaderInSection:section forColumnWidth:self.columnWidth];
        
        NSIndexPath *rootIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        
        UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:rootIndexPath];
        if (headerAttributes != nil) {
            headerAttributes.frame = CGRectMake(x, y, columnWidth, headerHeight);
            [self.estimatedHeaderAttributes addObject:headerAttributes];
        }
        
        sectionHeight += headerHeight;
        y += headerHeight;
        
        NSMutableArray *sectionItemAttributes = [NSMutableArray array];
        for (NSUInteger item = 0; item < [self numberOfItemsInSection:section]; item++) {
            y += self.interItemSpacing;
            CGFloat itemHeight = [self.delegate collectionView:self.collectionView estimatedHeightForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section] forColumnWidth:self.columnWidth];
            
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *itemAttributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
            if (itemAttributes != nil) {
                itemAttributes.frame = CGRectMake(x, y, columnWidth, itemHeight);
                [sectionItemAttributes addObject:itemAttributes];
            }
            
            sectionHeight += itemHeight;
            y += itemHeight;
        }
        [self.estimatedItemAttributes addObject:sectionItemAttributes];
        
        CGFloat footerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForFooterInSection:section forColumnWidth:self.columnWidth];
        UICollectionViewLayoutAttributes *footerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:rootIndexPath];
        if (footerAttributes != nil) {
            footerAttributes.frame = CGRectMake(x, y, columnWidth, footerHeight);
            [self.estimatedFooterAttributes addObject:footerAttributes];
        }
        
        sectionHeight += footerHeight;
        y+= footerHeight;
        
        _estimatedSectionHeights[section] = sectionHeight;
        
        currentColumnHeight += sectionHeight;
        _estimatedColumnHeights[currentColumnIndex] = currentColumnHeight;
        
        for (NSUInteger column = 0; column < self.numberOfColumns; column++) {
            CGFloat columnHeight = _estimatedColumnHeights[column];
            if (columnHeight < currentColumnHeight) { //switch to the shortest column
                currentColumnIndex = column;
                currentColumnHeight = columnHeight;
            }
        }
    }
    
    self.estimatedHeight = 0;
    for (NSUInteger column = 0; column < self.numberOfColumns; column++) {
        CGFloat columnHeight = _estimatedColumnHeights[column];
        if (columnHeight > self.estimatedHeight) {
            self.estimatedHeight = columnHeight;
        }
    }
    
}

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributesArray = [NSMutableArray array];
    
    for (NSArray *section in self.estimatedItemAttributes) {
        for (UICollectionViewLayoutAttributes *attributes in section) {
            if (CGRectIntersectsRect(attributes.frame, rect)) {
                [attributesArray addObject:attributes];
            }
        }
    }
    
    for (UICollectionViewLayoutAttributes *attributes in self.estimatedHeaderAttributes) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [attributesArray addObject:attributes];
        }
    }

    for (UICollectionViewLayoutAttributes *attributes in self.estimatedFooterAttributes) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [attributesArray addObject:attributes];
        }
    }
    
    return attributesArray;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - Invalidation

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !(CGSizeEqualToSize(newBounds.size, self.collectionView.frame.size));
}


//- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
//    return YES;
//}
//
//- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
//    WMFCollectionViewLayoutInvalidationContext *invalidationContext = (WMFCollectionViewLayoutInvalidationContext *)[super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
//    if (invalidationContext == nil) {
//        invalidationContext = [WMFCollectionViewLayoutInvalidationContext new];
//    }
//    invalidationContext.preferredLayoutAttributes = preferredAttributes;
//    invalidationContext.originalLayoutAttributes = originalAttributes;
//    return invalidationContext;
//}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context {
//    if ([context isKindOfClass:[WMFCollectionViewLayoutInvalidationContext class]]) {
//        WMFCollectionViewLayoutInvalidationContext *wmfContext = (WMFCollectionViewLayoutInvalidationContext *) context;
//        
//    }
    self.reestimateLayout = [context invalidateEverything];
    [super invalidateLayoutWithContext:context];
}

@end


@implementation WMFCollectionViewLayoutInvalidationContext
@end