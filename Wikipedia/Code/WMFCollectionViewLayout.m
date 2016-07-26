#import "WMFCollectionViewLayout.h"
#import "WMFCVLInfo.h"
#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"
#import "WMFCVLAttributes.h"
#import "WMFCVLInvalidationContext.h"

@interface WMFCollectionViewLayout ()

@property (nonatomic, readonly) id <WMFCollectionViewLayoutDelegate> delegate;
@property (nonatomic) CGFloat interColumnSpacing;
@property (nonatomic) CGFloat interSectionSpacing;
@property (nonatomic) CGFloat interItemSpacing;

@property (nonatomic) CGFloat height;

@property (nonatomic) NSInteger numberOfColumns;
@property (nonatomic, readonly) NSInteger numberOfSections;


@property (nonatomic, strong) WMFCVLInfo *info;
@property (nonatomic, strong) WMFCVLInfo *oldInfo;

@property (nonatomic) BOOL needsLayoutEstimate;

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
    self.needsLayoutEstimate = YES;
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

- (NSInteger)numberOfSections {
    return [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
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
    return CGSizeMake(self.collectionView.bounds.size.width, self.height);
}



- (void)estimateLayout {
    if (self.delegate == nil) {
        return;
    }
    
    UICollectionView *collectionView = self.collectionView;
    CGFloat columnWidth = floor(self.collectionView.bounds.size.width/self.numberOfColumns);
    
    UIEdgeInsets contentInset = collectionView.contentInset;
    
    CGFloat width = CGRectGetWidth(collectionView.bounds) - contentInset.left - contentInset.right;
    CGFloat height = CGRectGetHeight(collectionView.bounds) - contentInset.bottom - contentInset.top;
    
    
    WMFCVLInfo *oldInfo = self.info;
    self.oldInfo = oldInfo;
    WMFCVLInfo *newInfo = [[WMFCVLInfo alloc] initWithNumberOfColumns:self.numberOfColumns numberOfSections:self.numberOfSections];
    
    newInfo.collectionViewSize = collectionView.bounds.size;
    newInfo.width = width;
    newInfo.height = height;
    self.info = newInfo;
    
    __block WMFCVLColumn *currentColumn = newInfo.columns[0];
    
    [newInfo enumerateSectionsWithBlock:^(WMFCVLSection * _Nonnull section, NSUInteger sectionIndex, BOOL * _Nonnull stop) {
        CGFloat x = currentColumn.index * columnWidth;
        CGFloat y = currentColumn.height;
        CGPoint sectionOrigin = CGPointMake(x, y);
        
        currentColumn.width = columnWidth;
        
        [currentColumn addSection:section];
        
        CGFloat sectionHeight = 0;
        
        NSIndexPath *supplementaryViewIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
        
        WMFCVLAttributes *headerAttributes = [[oldInfo layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:supplementaryViewIndexPath] copy];
    
        CGFloat headerHeight = 0;
        if (headerAttributes == nil) {
            headerAttributes = [WMFCVLAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:supplementaryViewIndexPath];
            headerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForHeaderInSection:sectionIndex forColumnWidth:columnWidth];
             headerAttributes.frame = CGRectMake(x, y, columnWidth, headerHeight);
        } else {
            headerHeight = CGRectGetHeight(headerAttributes.frame);
        }
        
        [section addHeader:headerAttributes];
       
        sectionHeight += headerHeight;
        y += headerHeight;
        
        for (NSInteger item = 0; item < [self numberOfItemsInSection:sectionIndex]; item++) {
            y += self.interItemSpacing;

            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:sectionIndex];
            WMFCVLAttributes *itemAttributes = [[oldInfo layoutAttributesForItemAtIndexPath:itemIndexPath] copy];
            
            CGFloat itemHeight = 0;
            if (itemAttributes == nil) {
                itemAttributes = [WMFCVLAttributes layoutAttributesForCellWithIndexPath:itemIndexPath];
                itemHeight = [self.delegate collectionView:self.collectionView estimatedHeightForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:sectionIndex] forColumnWidth:columnWidth];
                itemAttributes.frame = CGRectMake(x, y, columnWidth, itemHeight);
            } else {
                itemHeight = CGRectGetHeight(itemAttributes.frame);
            }
            
            [section addItem:itemAttributes];

            sectionHeight += itemHeight;
            y += itemHeight;
        }
        
        CGFloat footerHeight = 0;
        WMFCVLAttributes *footerAttributes = [[oldInfo layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:supplementaryViewIndexPath] copy];
        if (footerAttributes == nil) {
            footerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForFooterInSection:sectionIndex forColumnWidth:columnWidth];
            footerAttributes = [WMFCVLAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:supplementaryViewIndexPath];
            footerAttributes.frame = CGRectMake(x, y, columnWidth, footerHeight);
        } else {
            footerHeight = CGRectGetHeight(footerAttributes.frame);
        }
        [section addFooter:footerAttributes];
        
        sectionHeight += footerHeight;
        y+= footerHeight;
        
        section.frame = (CGRect){sectionOrigin,  CGSizeMake(columnWidth, sectionHeight)};
        
        currentColumn.height = currentColumn.height + sectionHeight;

        __block CGFloat shortestColumnHeight = CGFLOAT_MAX;
        [newInfo enumerateColumnsWithBlock:^(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat columnHeight = column.height;
            if (columnHeight < shortestColumnHeight) { //switch to the shortest column
                currentColumn = column;
                shortestColumnHeight = columnHeight;
            }
        }];

    }];

    [self updateHeight];
}

- (void)updateHeight {
    self.height = 0;
    [self.info enumerateColumnsWithBlock:^(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat columnHeight = column.height;
        if (columnHeight > self.height) { //switch to the shortest column
            self.height = columnHeight;
        }
    }];
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
    if (self.needsLayoutEstimate) {
        [self estimateLayout];
        self.needsLayoutEstimate = NO;
    }
    [super prepareLayout];
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return newBounds.size.width != self.collectionView.bounds.size.width;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    WMFCVLInvalidationContext *invalidationContext = (WMFCVLInvalidationContext *)[super invalidationContextForBoundsChange:newBounds];
    invalidationContext.boundsDidChange = YES;
    [self updateLayoutForInvalidationContext:invalidationContext];
    return invalidationContext;
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    return originalAttributes.representedElementCategory == UICollectionElementCategoryCell && preferredAttributes.size.height != originalAttributes.size.height;
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
    if (context.boundsDidChange || context.invalidateDataSourceCounts || context.invalidateDataSourceCounts) {
        [self estimateLayout];
    } else if (context.originalLayoutAttributes && context.preferredLayoutAttributes) {
        UICollectionViewLayoutAttributes *originalAttributes = context.originalLayoutAttributes;
        UICollectionViewLayoutAttributes *preferredAttributes = context.preferredLayoutAttributes;
        NSIndexPath *indexPath = originalAttributes.indexPath;
        
        WMFCVLSection *invalidatedSection = self.info.sections[indexPath.section];
        WMFCVLColumn *invalidatedColumn = invalidatedSection.column;
        
        CGSize sizeToSet = preferredAttributes.frame.size;
        sizeToSet.width = invalidatedColumn.width;
        [invalidatedColumn setSize:sizeToSet forItemAtIndexPath:indexPath invalidationContext:context];
        
        [self updateHeight];
        
        CGSize contentSizeAdjustment = CGSizeMake(0, self.height - self.collectionView.contentSize.height);
        context.contentSizeAdjustment = contentSizeAdjustment;
    }
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context {
    if (context.invalidateEverything || context.invalidateDataSourceCounts) {
        self.needsLayoutEstimate = YES;
    }
    [super invalidateLayoutWithContext:context];
}
@end

