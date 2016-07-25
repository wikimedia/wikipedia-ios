#import "WMFCollectionViewLayout.h"

@interface WMFCVLInvalidationContext : UICollectionViewLayoutInvalidationContext
@property (nonatomic, copy) UICollectionViewLayoutAttributes *originalLayoutAttributes;
@property (nonatomic, copy) UICollectionViewLayoutAttributes *preferredLayoutAttributes;
@end

@implementation WMFCVLInvalidationContext
@end


@interface WMFCVLAttributes : UICollectionViewLayoutAttributes
@end

@implementation WMFCVLAttributes
@end


@class WMFCVLColumn;

@interface WMFCVLSection : NSObject
@property (nonatomic) NSUInteger index;
@property (nonatomic) CGRect frame;
@property (nonatomic, weak) WMFCVLColumn *column;
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

@end


@interface WMFCVLColumn : NSObject
@property (nonatomic) NSUInteger index;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@property (nonatomic, strong) NSMutableArray <WMFCVLSection *> *sections;
- (void)addSection:(nonnull WMFCVLSection *)section;
@end

@implementation WMFCVLColumn

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sections = [NSMutableArray array];
    }
    return self;
}

- (void)addSection:(nonnull WMFCVLSection *)section {
    section.column = self;
    [self.sections addObject:section];
}

@end


@interface WMFCVLInfo : NSObject
@property (nonatomic) NSMutableArray <WMFCVLColumn *> *columns;
@property (nonatomic) NSMutableArray <WMFCVLSection *> *sections;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGSize collectionViewSize;

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns numberOfSections:(NSUInteger)numberOfSections NS_DESIGNATED_INITIALIZER;
- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop))block;
- (void)enumerateColumnsWithBlock:(nonnull void(^)(WMFCVLColumn * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop))block;
@end

@implementation WMFCVLInfo

- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns numberOfSections:(NSUInteger)numberOfSections
{
    self = [super init];
    if (self) {
        self.columns = [NSMutableArray arrayWithCapacity:numberOfColumns];
        for (NSUInteger i = 0; i < numberOfColumns; i++) {
            WMFCVLColumn *column = [WMFCVLColumn new];
            column.index = i;
            [self.columns addObject:column];
        }
        
        self.sections = [NSMutableArray arrayWithCapacity:numberOfSections];
        for (NSUInteger i = 0; i < numberOfSections; i++) {
            WMFCVLSection *section = [WMFCVLSection new];
            section.index = i;
            [self.sections addObject:section];
        }
    }
    return self;
}

- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.sections enumerateObjectsUsingBlock:block];
}

- (void)enumerateColumnsWithBlock:(nonnull void(^)(WMFCVLColumn * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.columns enumerateObjectsUsingBlock:block];
}

@end

@interface WMFCollectionViewLayout ()

@property (nonatomic, readonly) id <WMFCollectionViewLayoutDelegate> delegate;
@property (nonatomic) CGFloat interColumnSpacing;
@property (nonatomic) CGFloat interSectionSpacing;
@property (nonatomic) CGFloat interItemSpacing;

@property (nonatomic) CGFloat height;

@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfSections;


@property (nonatomic, strong) WMFCVLInfo *info;
@property (nonatomic, strong) WMFCVLInfo *oldInfo;

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
        
        
        NSIndexPath *sectionIndexPath = [self indexPathForSupplementaryViewInSection:sectionIndex];
        
        WMFCVLAttributes *headerAttributes = (WMFCVLAttributes *)[self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:sectionIndexPath];
        if (headerAttributes != nil) {
            headerAttributes.frame = CGRectMake(x, y, columnWidth, headerHeight);
            [section.headers addObject:headerAttributes];
        }
        
        sectionHeight += headerHeight;
        y += headerHeight;
        
        for (NSUInteger item = 0; item < [self numberOfItemsInSection:sectionIndex]; item++) {
            y += self.interItemSpacing;
            CGFloat itemHeight = [self.delegate collectionView:self.collectionView estimatedHeightForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:sectionIndex] forColumnWidth:columnWidth];
            
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:sectionIndex];
            WMFCVLAttributes *itemAttributes = (WMFCVLAttributes *)[self layoutAttributesForItemAtIndexPath:itemIndexPath];
            if (itemAttributes != nil) {
                itemAttributes.frame = CGRectMake(x, y, columnWidth, itemHeight);
                [section.items addObject:itemAttributes];
            }
            assert(itemHeight > 0);
            sectionHeight += itemHeight;
            y += itemHeight;
        }
        
        CGFloat footerHeight = [self.delegate collectionView:self.collectionView estimatedHeightForFooterInSection:sectionIndex forColumnWidth:columnWidth];
        WMFCVLAttributes *footerAttributes = (WMFCVLAttributes *)[self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:sectionIndexPath];
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

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    WMFCVLInvalidationContext *invalidationContext = (WMFCVLInvalidationContext *)[super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
    if (invalidationContext == nil) {
        invalidationContext = [WMFCVLInvalidationContext new];
    }
    invalidationContext.preferredLayoutAttributes = preferredAttributes;
    invalidationContext.originalLayoutAttributes = originalAttributes;
    return invalidationContext;
}

- (void)updateAttributes:(WMFCVLAttributes *)attributes withDeltaHeight:(CGFloat)deltaHeight {
    CGPoint newCenter = attributes.center;
    newCenter.y = newCenter.y + deltaHeight;
    WMFCVLAttributes *newAttributes = [attributes copy];
    newAttributes.center = newCenter;
    if (newAttributes.representedElementCategory == UICollectionElementCategoryCell) {
        self.info.sections[newAttributes.indexPath.section].items[newAttributes.indexPath.item] = newAttributes;
    } else if ([newAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
       self.info.sections[newAttributes.indexPath.section].headers[newAttributes.indexPath.item] = newAttributes;
    } else if ([newAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
       self.info.sections[newAttributes.indexPath.section].footers[newAttributes.indexPath.item] = newAttributes;
    }
}

- (NSIndexPath *)indexPathForSupplementaryViewInSection:(NSUInteger)section {
    return [NSIndexPath indexPathForItem:0 inSection:section];
}

- (void)prepareLayout {
    [self estimateLayout];
    [super prepareLayout];
}

@end

