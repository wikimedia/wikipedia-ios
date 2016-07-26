#import "WMFCollectionViewLayout.h"

@interface WMFCVLInvalidationContext : UICollectionViewLayoutInvalidationContext
@property (nonatomic, copy) UICollectionViewLayoutAttributes *originalLayoutAttributes;
@property (nonatomic, copy) UICollectionViewLayoutAttributes *preferredLayoutAttributes;
@property (nonatomic) BOOL boundsDidChange;
@end

@implementation WMFCVLInvalidationContext
@end

@interface WMFCVLAttributes : UICollectionViewLayoutAttributes
@end

@implementation WMFCVLAttributes
@end

@class WMFCVLColumn;

@interface WMFCVLSection : NSObject
@property (nonatomic) NSInteger index;
@property (nonatomic) CGRect frame;
@property (nonatomic, weak) WMFCVLColumn *column;
@property (nonatomic) CGFloat interItemSpacing;
@property (nonatomic, strong) NSMutableArray <WMFCVLAttributes *> *headers;
@property (nonatomic, strong) NSMutableArray <WMFCVLAttributes *> *footers;
@property (nonatomic, strong) NSMutableArray <WMFCVLAttributes *> *items;
- (void)enumerateLayoutAttributesWithBlock:(void(^)(WMFCVLAttributes *layoutAttributes, BOOL *stop))block;
@end

@implementation WMFCVLSection

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.headers = [NSMutableArray array];
        self.footers = [NSMutableArray array];
        self.items = [NSMutableArray array];
    }
    return self;
}

- (void)enumerateLayoutAttributesWithBlock:(void(^)(WMFCVLAttributes *layoutAttributes, BOOL *stop))block {
    __block BOOL bigStop = NO;
    
    [self.headers enumerateObjectsUsingBlock:^(WMFCVLAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, &bigStop);
        *stop = bigStop;
    }];
    
    if (bigStop) {
        return;
    }
    [self.items enumerateObjectsUsingBlock:^(WMFCVLAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, &bigStop);
        *stop = bigStop;
    }];
    
    if (bigStop) {
        return;
    }
    
    [self.footers enumerateObjectsUsingBlock:^(WMFCVLAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, &bigStop);
        *stop = bigStop;
    }];
}

- (void)offsetByDistance:(CGFloat)deltaY invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    if (ABS(deltaY) > 0) {
        [self offsetHeadersStartingAtIndex:0 distance:deltaY invalidationContext:invalidationContext];
        [self offsetItemsStartingAtIndex:0 distance:deltaY invalidationContext:invalidationContext];
        [self offsetFootersStartingAtIndex:0 distance:deltaY invalidationContext:invalidationContext];
    }
}

- (CGFloat)setSize:(CGSize)size forHeaderAtIndex:(NSInteger)headerIndex invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    CGFloat deltaH = [self setSize:size forAttributesAtIndex:headerIndex inArray:self.headers];
    
    if (ABS(deltaH) > 0) {
        [self offsetHeadersStartingAtIndex:headerIndex + 1 distance:deltaH invalidationContext:invalidationContext];
        [self offsetItemsStartingAtIndex:0 distance:deltaH invalidationContext:invalidationContext];
        [self offsetFootersStartingAtIndex:0 distance:deltaH invalidationContext:invalidationContext];
    }
    
    return deltaH;
}

- (CGFloat)setSize:(CGSize)size forFooterAtIndex:(NSInteger)footerIndex invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    CGFloat deltaH = [self setSize:size forAttributesAtIndex:footerIndex inArray:self.footers];
    
    if (ABS(deltaH) > 0) {
        [self offsetFootersStartingAtIndex:footerIndex + 1 distance:deltaH invalidationContext:invalidationContext];
    }
    
    return deltaH;
}

- (CGFloat)setSize:(CGSize)size forItemAtIndex:(NSInteger)index invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    CGFloat deltaH = [self setSize:size forAttributesAtIndex:index inArray:self.items];
    
    if (ABS(deltaH) > 0) {
        [self offsetItemsStartingAtIndex:index + 1 distance:deltaH invalidationContext:invalidationContext];
        [self offsetFootersStartingAtIndex:0 distance:deltaH invalidationContext:invalidationContext];
    }
    
    return deltaH;
}

- (CGFloat)setSize:(CGSize)size forAttributesAtIndex:(NSInteger)index inArray:(NSMutableArray *)attributes {
    WMFCVLAttributes *newAttributes = [attributes[index] copy];
    
    if (CGSizeEqualToSize(size, newAttributes.frame.size)) {
        return 0;
    }
    
    CGFloat deltaH = size.height - newAttributes.frame.size.height;
    newAttributes.frame = (CGRect) {newAttributes.frame.origin, size};
    attributes[index] = newAttributes;
    return deltaH;
}

- (void)offsetHeadersStartingAtIndex:(NSInteger)headerIndex distance:(CGFloat)deltaY invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    NSArray *invalidatedHeaderIndexPaths = [self offsetAttributesInArray:self.headers startingAtIndex:headerIndex distance:deltaY];
    [invalidationContext invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:invalidatedHeaderIndexPaths];
}

- (void)offsetItemsStartingAtIndex:(NSInteger)itemIndex distance:(CGFloat)deltaY invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    NSArray *invalidatedItemIndexPaths = [self offsetAttributesInArray:self.items startingAtIndex:itemIndex distance:deltaY];
    [invalidationContext invalidateItemsAtIndexPaths:invalidatedItemIndexPaths];
}

- (void)offsetFootersStartingAtIndex:(NSInteger)footerIndex distance:(CGFloat)deltaY invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    NSArray *invalidatedFooterIndexPaths = [self offsetAttributesInArray:self.footers startingAtIndex:footerIndex distance:deltaY];
    [invalidationContext invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionFooter atIndexPaths:invalidatedFooterIndexPaths];
}

- (NSArray *)offsetAttributesInArray:(NSMutableArray *)attributes startingAtIndex:(NSInteger)index distance:(CGFloat)deltaY {
    NSInteger count = attributes.count - index;
    if (count <= 0) {
        return nil;
    }
    NSMutableArray *invalidatedIndexPaths = [NSMutableArray arrayWithCapacity:count];
    while (index < attributes.count) {
        WMFCVLAttributes *newAttributes = [attributes[index] copy];
        newAttributes.frame = CGRectOffset(newAttributes.frame, 0, deltaY);
        attributes[index] = newAttributes;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:self.index];
        [invalidatedIndexPaths addObject:indexPath];
        index++;
    }
    return invalidatedIndexPaths;
}

@end


@interface WMFCVLColumn : NSObject
@property (nonatomic) NSInteger index;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@property (nonatomic, strong) NSMutableArray <WMFCVLSection *> *sections;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, WMFCVLSection *> *sectionsByIndex;
- (void)addSection:(nonnull WMFCVLSection *)section;
- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block;
@end

@implementation WMFCVLColumn

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sections = [NSMutableArray array];
        self.sectionsByIndex = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addSection:(nonnull WMFCVLSection *)section {
    section.column = self;
    self.sectionsByIndex[@(section.index)] = section;
    [self.sections addObject:section];
}

- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.sections enumerateObjectsUsingBlock:block];
}

- (void)setSize:(CGSize)size forHeaderAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;
    
    WMFCVLSection *section = self.sectionsByIndex[@(sectionIndex)];
    CGFloat deltaY = [section setSize:size forHeaderAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];
    self.height += deltaY;
    invalidationContext.contentSizeAdjustment = CGSizeMake(0, deltaY);
}

- (void)setSize:(CGSize)size forFooterAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;
    
    WMFCVLSection *section = self.sectionsByIndex[@(sectionIndex)];
    CGFloat deltaY = [section setSize:size forFooterAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];
    self.height += deltaY;
    invalidationContext.contentSizeAdjustment = CGSizeMake(0, deltaY);
}

- (void)setSize:(CGSize)size forItemAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;
    
    WMFCVLSection *section = self.sectionsByIndex[@(sectionIndex)];
    CGFloat deltaY = [section setSize:size forItemAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];
    self.height += deltaY;
    invalidationContext.contentSizeAdjustment = CGSizeMake(0, deltaY);
}

- (void)offsetSectionsByDistance:(CGFloat)deltaY startingAfterSection:(WMFCVLSection *)afterSection invalidationContext:(UICollectionViewLayoutInvalidationContext *)invalidationContext {
    if (ABS(deltaY) == 0) {
        return;
    }
    
    BOOL update = NO;
    for (WMFCVLSection *section in self.sections) {
        if (section == afterSection) {
            update = YES;
        } else if (update) {
            [section offsetByDistance:deltaY invalidationContext:invalidationContext];
        }
    }
}

@end


@interface WMFCVLInfo : NSObject
@property (nonatomic) NSMutableArray <WMFCVLColumn *> *columns;
@property (nonatomic) NSMutableArray <WMFCVLSection *> *sections;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGSize collectionViewSize;

- (instancetype)initWithNumberOfColumns:(NSInteger)numberOfColumns numberOfSections:(NSInteger)numberOfSections NS_DESIGNATED_INITIALIZER;
- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block;
- (void)enumerateColumnsWithBlock:(nonnull void(^)(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop))block;
@end

@implementation WMFCVLInfo

- (instancetype)initWithNumberOfColumns:(NSInteger)numberOfColumns numberOfSections:(NSInteger)numberOfSections
{
    self = [super init];
    if (self) {
        self.columns = [NSMutableArray arrayWithCapacity:numberOfColumns];
        for (NSInteger i = 0; i < numberOfColumns; i++) {
            WMFCVLColumn *column = [WMFCVLColumn new];
            column.index = i;
            [self.columns addObject:column];
        }
        
        self.sections = [NSMutableArray arrayWithCapacity:numberOfSections];
        for (NSInteger i = 0; i < numberOfSections; i++) {
            WMFCVLSection *section = [WMFCVLSection new];
            section.index = i;
            [self.sections addObject:section];
        }
    }
    return self;
}

- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.sections enumerateObjectsUsingBlock:block];
}

- (void)enumerateColumnsWithBlock:(nonnull void(^)(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.columns enumerateObjectsUsingBlock:block];
}

@end

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

@property (nonatomic) BOOL needsLayout;

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
    self.needsLayout = YES;
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


- (void)resetLayout {
    self.oldInfo = self.info;
    self.info = [[WMFCVLInfo alloc] initWithNumberOfColumns:self.numberOfColumns numberOfSections:self.numberOfSections];
}

- (void)estimateLayout {
    if (self.delegate == nil) {
        return;
    }
    
    [self resetLayout];
    
    UICollectionView *collectionView = self.collectionView;
    CGFloat columnWidth = floor(self.collectionView.bounds.size.width/self.numberOfColumns);
    
    UIEdgeInsets contentInset = collectionView.contentInset;
    
    CGFloat width = CGRectGetWidth(collectionView.bounds) - contentInset.left - contentInset.right;
    CGFloat height = CGRectGetHeight(collectionView.bounds) - contentInset.bottom - contentInset.top;
    
    self.info.collectionViewSize = collectionView.bounds.size;
    self.info.width = width;
    self.info.height = height;
    
    
    __block WMFCVLColumn *currentColumn = self.info.columns[0];
    
    [self.info enumerateSectionsWithBlock:^(WMFCVLSection * _Nonnull section, NSUInteger sectionIndex, BOOL * _Nonnull stop) {
        CGFloat x = currentColumn.index * columnWidth;
        CGFloat y = currentColumn.height;
        CGPoint sectionOrigin = CGPointMake(x, y);
        
        currentColumn.width = columnWidth;
        
        [currentColumn addSection:section];
        
        CGFloat sectionHeight = 0;
        
        CGFloat headerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForHeaderInSection:sectionIndex forColumnWidth:columnWidth];
        
        
        NSIndexPath *supplementaryViewIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
        
        WMFCVLAttributes *headerAttributes = (WMFCVLAttributes *)[WMFCVLAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:supplementaryViewIndexPath];
        if (headerAttributes != nil) {
            headerAttributes.frame = CGRectMake(x, y, columnWidth, headerHeight);
            [section.headers addObject:headerAttributes];
        }
        
        sectionHeight += headerHeight;
        y += headerHeight;
        
        for (NSInteger item = 0; item < [self numberOfItemsInSection:sectionIndex]; item++) {
            y += self.interItemSpacing;
            CGFloat itemHeight = [self.delegate collectionView:self.collectionView estimatedHeightForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:sectionIndex] forColumnWidth:columnWidth];
            
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:sectionIndex];
            WMFCVLAttributes *itemAttributes = (WMFCVLAttributes *)[WMFCVLAttributes layoutAttributesForCellWithIndexPath:itemIndexPath];
            if (itemAttributes != nil) {
                itemAttributes.frame = CGRectMake(x, y, columnWidth, itemHeight);
                [section.items addObject:itemAttributes];
            }
            assert(itemHeight > 0);
            sectionHeight += itemHeight;
            y += itemHeight;
        }
        
        CGFloat footerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForFooterInSection:sectionIndex forColumnWidth:columnWidth];
        WMFCVLAttributes *footerAttributes = (WMFCVLAttributes *)[WMFCVLAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:supplementaryViewIndexPath];
        if (footerAttributes != nil) {
            assert(footerHeight > 0);
            footerAttributes.frame = CGRectMake(x, y, columnWidth, footerHeight);
            assert(footerAttributes.frame.size.width > 0);
            [section.footers addObject:footerAttributes];
        }
        
        sectionHeight += footerHeight;
        y+= footerHeight;
        
        section.frame = (CGRect){sectionOrigin,  CGSizeMake(columnWidth, sectionHeight)};
        
        currentColumn.height = currentColumn.height + sectionHeight;

        __block CGFloat shortestColumnHeight = CGFLOAT_MAX;
        [self.info enumerateColumnsWithBlock:^(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
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
    NSInteger sectionIndex = indexPath.section;
    
    if (sectionIndex < 0 || sectionIndex >= self.info.sections.count) {
        return nil;
    }
    
    WMFCVLAttributes *attributes = self.info.sections[indexPath.section].items[indexPath.item];
    assert(attributes != nil);
    return attributes;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    NSInteger sectionIndex = indexPath.section;
    if (sectionIndex < 0 || sectionIndex >= self.info.sections.count) {
        return nil;
    }
    
    WMFCVLAttributes *attributes = nil;
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        attributes = self.info.sections[indexPath.section].headers[indexPath.item];
    } else if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        attributes = self.info.sections[indexPath.section].footers[indexPath.item];
    }
    
    assert(attributes != nil);
    return attributes;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - Invalidation

- (void)prepareLayout {
    if (self.needsLayout) {
        [self estimateLayout];
        self.needsLayout = NO;
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
    if (context.invalidateDataSourceCounts || context.invalidateDataSourceCounts) {
        self.needsLayout = YES;
    }
    [super invalidateLayoutWithContext:context];
}
@end

