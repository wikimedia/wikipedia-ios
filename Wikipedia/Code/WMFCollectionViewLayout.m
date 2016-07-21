#import "WMFCollectionViewLayout.h"

@interface WMFCollectionViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext
@property (nonatomic, copy) UICollectionViewLayoutAttributes *originalLayoutAttributes;
@property (nonatomic, copy) UICollectionViewLayoutAttributes *preferredLayoutAttributes;
@end

@interface WMFCollectionViewLayout () {
    CGFloat *_sectionHeights;
    CGFloat *_columnHeights;
    NSUInteger *_columnBySection;
}

@property (nonatomic, readonly) id <WMFCollectionViewLayoutDelegate> delegate;
@property (nonatomic) CGFloat interColumnSpacing;
@property (nonatomic) CGFloat interSectionSpacing;
@property (nonatomic) CGFloat interItemSpacing;

@property (nonatomic) CGFloat height;

@property (nonatomic) NSMutableArray *headerAttributes;
@property (nonatomic) NSMutableArray *footerAttributes;
@property (nonatomic) NSMutableArray *itemAttributes;

@property (nonatomic) CGFloat columnWidth;
@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfSections;

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

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.bounds.size.width, self.height);
}

- (void)estimateLayout {
    self.headerAttributes = [NSMutableArray array];
    self.footerAttributes = [NSMutableArray array];
    self.itemAttributes   = [NSMutableArray array];
    self.columnWidth = floor(self.collectionView.bounds.size.width/self.numberOfColumns);
    
    free(_sectionHeights);
    _sectionHeights = malloc(self.numberOfSections*sizeof(CGFloat));
    
    free(_columnBySection);
    _columnBySection = malloc(self.numberOfSections*sizeof(NSUInteger));
    
    free(_columnHeights);
    _columnHeights = malloc(self.numberOfColumns*sizeof(CGFloat));
    
    if (self.delegate == nil) {
        return;
    }
    CGFloat columnWidth = self.columnWidth;
    CGFloat currentColumnHeight = 0;
    NSUInteger currentColumnIndex = 0;
    
    for (NSUInteger section = 0; section < self.numberOfSections; section++) {
        CGFloat x = currentColumnIndex * self.columnWidth;
        CGFloat y = currentColumnHeight;
        _columnBySection[section] = currentColumnIndex;
        
        CGFloat sectionHeight = 0;
        
        CGFloat headerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForHeaderInSection:section forColumnWidth:self.columnWidth];
        
        NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:section];
        
        UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:sectionIndexPath];
        if (headerAttributes != nil) {
            headerAttributes.frame = CGRectMake(x, y, columnWidth, headerHeight);
            [self.headerAttributes addObject:headerAttributes];
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
            assert(itemHeight > 0);
            sectionHeight += itemHeight;
            y += itemHeight;
        }
        [self.itemAttributes addObject:sectionItemAttributes];
        
        CGFloat footerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForFooterInSection:section forColumnWidth:self.columnWidth];
        UICollectionViewLayoutAttributes *footerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:sectionIndexPath];
        if (footerAttributes != nil) {
            assert(footerHeight > 0);
            footerAttributes.frame = CGRectMake(x, y, columnWidth, footerHeight);
            assert(footerAttributes.frame.size.width > 0);
            [self.footerAttributes addObject:footerAttributes];
        }
        
        sectionHeight += footerHeight;
        y+= footerHeight;
        
        _sectionHeights[section] = sectionHeight;
        
        currentColumnHeight += sectionHeight;
        _columnHeights[currentColumnIndex] = currentColumnHeight;
        
        for (NSUInteger column = 0; column < self.numberOfColumns; column++) {
            CGFloat columnHeight = _columnHeights[column];
            if (columnHeight < currentColumnHeight) { //switch to the shortest column
                currentColumnIndex = column;
                currentColumnHeight = columnHeight;
            }
        }
    }
    
    [self updateHeight];
}

- (void)updateHeight {
    self.height = 0;
    for (NSUInteger column = 0; column < self.numberOfColumns; column++) {
        CGFloat columnHeight = _columnHeights[column];
        if (columnHeight > self.height) {
            self.height = columnHeight;
        }
    }
}

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributesArray = [NSMutableArray array];
    
    for (NSArray *section in self.itemAttributes) {
        for (UICollectionViewLayoutAttributes *attributes in section) {
            if (CGRectIntersectsRect(attributes.frame, rect)) {
                [attributesArray addObject:attributes];
            }
        }
    }
    for (UICollectionViewLayoutAttributes *attributes in self.headerAttributes) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [attributesArray addObject:attributes];
        }
    }
    
    for (UICollectionViewLayoutAttributes *attributes in self.footerAttributes) {
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

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    return !CGSizeEqualToSize(preferredAttributes.size, originalAttributes.size);
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    WMFCollectionViewLayoutInvalidationContext *invalidationContext = (WMFCollectionViewLayoutInvalidationContext *)[super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
    if (invalidationContext == nil) {
        invalidationContext = [WMFCollectionViewLayoutInvalidationContext new];
    }
    invalidationContext.preferredLayoutAttributes = preferredAttributes;
    invalidationContext.originalLayoutAttributes = originalAttributes;
    return invalidationContext;
}

- (void)updateAttributes:(UICollectionViewLayoutAttributes *)attributes withDeltaHeight:(CGFloat)deltaHeight {
    CGPoint newCenter = attributes.center;
    newCenter.y = newCenter.y + deltaHeight;
    UICollectionViewLayoutAttributes *newAttributes = [attributes copy];
    newAttributes.center = newCenter;
    assert(newAttributes.frame.size.width == self.columnWidth);
    if (newAttributes.representedElementCategory == UICollectionElementCategoryCell) {
        self.itemAttributes[newAttributes.indexPath.section][newAttributes.indexPath.item] = newAttributes;
    } else if ([newAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        self.headerAttributes[newAttributes.indexPath.section] = newAttributes;
    } else if ([newAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        self.footerAttributes[newAttributes.indexPath.section] = newAttributes;
    }
}

- (void)updateLayoutForInvalidationContext:(WMFCollectionViewLayoutInvalidationContext *)context {
    UICollectionViewLayoutAttributes *originalAttributes = context.originalLayoutAttributes;
    UICollectionViewLayoutAttributes *preferredAttributes = context.preferredLayoutAttributes;
    NSIndexPath *indexPath = originalAttributes.indexPath;
    CGFloat deltaHeight = preferredAttributes.size.height - originalAttributes.size.height;
    _sectionHeights[indexPath.section] += deltaHeight;
    NSUInteger column = _columnBySection[indexPath.section];
    _columnHeights[column] += deltaHeight;
    
    BOOL shouldUpdateItemsAndFooter = YES;
    UICollectionViewLayoutAttributes *attributes = [originalAttributes copy];
    CGRect newFrame = attributes.frame;
    newFrame.size.height = preferredAttributes.size.height;
    newFrame.size.width = self.columnWidth;
    attributes.frame = newFrame;
    
    if (originalAttributes.representedElementCategory == UICollectionElementCategoryCell) {
        self.itemAttributes[indexPath.section][indexPath.item] = attributes;
    } else if ([originalAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        self.headerAttributes[indexPath.section] = attributes;
    } else if ([originalAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        self.footerAttributes[indexPath.section] = attributes;
        shouldUpdateItemsAndFooter = false;
    }

    NSMutableArray *invalidatedHeaderIndexPaths = [NSMutableArray array];
    NSMutableArray *invalidatedItemIndexPaths = [NSMutableArray array];
    NSMutableArray *invalidatedFooterIndexPaths = [NSMutableArray array];
    
    NSUInteger item = indexPath.item + 1;
   
    for (NSUInteger section = indexPath.section; section < self.numberOfSections; section++) {
        if (_columnBySection[section] == column) {
            NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:section];
            if (item == 0) {
                [self updateAttributes:self.headerAttributes[section] withDeltaHeight:deltaHeight];
                [invalidatedHeaderIndexPaths addObject:sectionIndexPath];
            }
            if (shouldUpdateItemsAndFooter) {
                NSArray *items = self.itemAttributes[section];
                while (item < items.count) {
                    UICollectionViewLayoutAttributes *attributes = items[item];
                    [self updateAttributes:attributes withDeltaHeight:deltaHeight];
                    NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
                    [invalidatedItemIndexPaths addObject:itemIndexPath];
                    item++;
                }
                item = 0;
                
                [self updateAttributes:self.footerAttributes[section] withDeltaHeight:deltaHeight];
                [invalidatedFooterIndexPaths addObject:sectionIndexPath];
                
            }
            shouldUpdateItemsAndFooter = YES;
        }
    }
    
    [self updateHeight];
    
    CGSize contentSizeAdjustment = CGSizeMake(0, self.height - self.collectionView.contentSize.height);
    context.contentSizeAdjustment = contentSizeAdjustment;
    
    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:invalidatedHeaderIndexPaths];
    [context invalidateItemsAtIndexPaths:invalidatedItemIndexPaths];
    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionFooter atIndexPaths:invalidatedFooterIndexPaths];
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context {
    if ([context invalidateEverything] || [context invalidateDataSourceCounts]) {
        [self estimateLayout];
    }
    if ([context isKindOfClass:[WMFCollectionViewLayoutInvalidationContext class]]) {
        WMFCollectionViewLayoutInvalidationContext *wmfContext = (WMFCollectionViewLayoutInvalidationContext *) context;
        if (wmfContext.preferredLayoutAttributes && wmfContext.originalLayoutAttributes) {
            [self updateLayoutForInvalidationContext:wmfContext];
        }
    }
    [super invalidateLayoutWithContext:context];

}

@end


@implementation WMFCollectionViewLayoutInvalidationContext
@end