//
//  SelfSizingWaterfallCollectionViewLayout.m
//  SelfSizingWaterfallCollectionViewLayout
//
//  Created by Adam Waite on 01/10/2014.
//  Copyright (c) 2014 adamjwaite.co.uk. All rights reserved.
//

#import "SelfSizingWaterfallCollectionViewLayout.h"

@interface SelfSizingWaterfallCollectionViewLayout ()

@property (weak, nonatomic) id<SelfSizingWaterfallCollectionViewLayoutDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *columnHeights;
@property (strong, nonatomic) NSMutableArray *headerAttributes;
@property (strong, nonatomic) NSMutableArray *footerAttributes;
@property (strong, nonatomic) NSMutableDictionary *preferredItemAttributes;
@property (strong, nonatomic) NSMutableDictionary *allItemAttributes;
@property (nonatomic, readonly) NSUInteger numberOfSections;

@end

@implementation SelfSizingWaterfallCollectionViewLayout


#pragma mark -
#pragma mark Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _sectionInset = UIEdgeInsetsZero;
    _numberOfColumns = 2;
    _minimumInteritemSpacing = 8.0f;
    _minimumLineSpacing = 8.0f;
    _headerReferenceSize = CGSizeZero;
    _footerReferenceSize = CGSizeZero;
    _estimatedItemHeight = 100.0f;
}



#pragma mark -
#pragma mark Accessors

#pragma mark Delegate

- (id<SelfSizingWaterfallCollectionViewLayoutDelegate>)delegate
{
    return (id<SelfSizingWaterfallCollectionViewLayoutDelegate>)self.collectionView.delegate;
}

#pragma mark Layout Properties and Convinient Access

- (NSUInteger)numberOfSections
{
    return [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
}

- (void)setSectionInset:(UIEdgeInsets)sectionInsets
{
    if (!UIEdgeInsetsEqualToEdgeInsets(_sectionInset, sectionInsets)) {
        _sectionInset = sectionInsets;
        [self invalidateLayout];
    }
}

- (UIEdgeInsets)sectionInsetsInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    }
    return self.sectionInset;
}

- (void)setNumberOfColumns:(NSUInteger)columnCount
{
    if (_numberOfColumns != columnCount) {
        _numberOfColumns = columnCount;
        [self invalidateLayout];
    }
}

- (NSUInteger)numberOfColumnsInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:numberOfColumnsInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self numberOfColumnsInSection:section];
    }
    return self.numberOfColumns;
}

- (void)setMinimumInteritemSpacing:(CGFloat)minimumInteritemSpacing
{
    if (_minimumInteritemSpacing != minimumInteritemSpacing) {
        _minimumInteritemSpacing = minimumInteritemSpacing;
        [self invalidateLayout];
    }
}

- (CGFloat)minimumInteritemSpacingInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
    }
    return self.minimumInteritemSpacing;
}

- (void)setMinimumLineSpacing:(CGFloat)minimumLineSpacing
{
    if (_minimumLineSpacing != minimumLineSpacing) {
        _minimumLineSpacing = minimumLineSpacing;
        [self invalidateLayout];
    }
}

- (CGFloat)minimumLineSpacingInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
    }
    return self.minimumLineSpacing;
}

- (void)setHeaderReferenceSize:(CGSize)headerReferenceSize
{
    if (!CGSizeEqualToSize(_headerReferenceSize, headerReferenceSize)) {
        _headerReferenceSize = headerReferenceSize;
        [self invalidateLayout];
    }
}

- (CGSize)headerReferenceSizeInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
    }
    return self.headerReferenceSize;
}

- (void)setFooterReferenceSize:(CGSize)footerReferenceSize
{
    if (!CGSizeEqualToSize(_footerReferenceSize, footerReferenceSize)) {
        _footerReferenceSize = footerReferenceSize;
        [self invalidateLayout];
    }
}

- (CGSize)footerReferenceSizeInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:section];
    }
    return self.footerReferenceSize;
}

- (void)setEstimatedItemHeight:(CGFloat)estimatedItemHeight
{
    if (_estimatedItemHeight != estimatedItemHeight) {
        _estimatedItemHeight = estimatedItemHeight;
        [self invalidateLayout];
    }
}

- (CGFloat)estimatedItemHeightForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:estimatedHeightForItemAtIndexPath:)]) {
        return [self.delegate collectionView:self.collectionView layout:self estimatedHeightForItemAtIndexPath:indexPath];
    }
    
    return self.estimatedItemHeight;
}

#pragma mark Internal State

- (NSMutableArray *)columnHeights
{
    if (!_columnHeights) {
        _columnHeights = [NSMutableArray array];
    }
    return _columnHeights;
}

- (NSMutableArray *)headerAttributes
{
    if (!_headerAttributes) {
        _headerAttributes = [NSMutableArray array];
    }
    return _headerAttributes;
}

- (NSMutableArray *)footerAttributes
{
    if (!_footerAttributes) {
        _footerAttributes = [NSMutableArray array];
    }
    return _footerAttributes;
}

- (NSMutableDictionary *)allItemAttributes
{
    if (!_allItemAttributes) {
        _allItemAttributes = [NSMutableDictionary dictionary];
    }
    return _allItemAttributes;
}

- (NSMutableDictionary *)preferredItemAttributes
{
    if (!_preferredItemAttributes) {
        _preferredItemAttributes = [NSMutableDictionary dictionary];
    }
    return _preferredItemAttributes;
}



#pragma mark -
#pragma mark Layout Preparation

- (void)prepareLayout
{
    [super prepareLayout];
    [self resetColumnHeights];
    
    for (NSInteger section = 0; section < self.numberOfSections; ++section) {
        [self prepareSection:section];
    }
}

- (void)resetColumnHeights
{
    [@[self.allItemAttributes, self.columnHeights, self.headerAttributes, self.footerAttributes] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeAllObjects];
    }];
    
    for (NSUInteger section = 0; section < self.numberOfSections; section++) {
        
        NSUInteger numberOfColumns = [self numberOfColumnsInSection:section];
        NSMutableArray *sectionColumnHeights = [NSMutableArray arrayWithCapacity:numberOfColumns];
        
        [self.headerAttributes addObject:[NSNull null]];
        [self.footerAttributes addObject:[NSNull null]];
        
        for (NSUInteger column = 0; column < numberOfColumns; column++) {
            [sectionColumnHeights addObject:@(0)];
        }
        
        [self.columnHeights addObject:sectionColumnHeights];
    }
}

- (void)prepareSection:(NSUInteger)section
{
    NSUInteger numberOfColumns = [self numberOfColumnsInSection:section];
    CGFloat reverseTetrisPoint = [[[self allSectionHeights] valueForKeyPath:@"@sum.floatValue"] floatValue];
    
    CGFloat topInset = [self sectionInsetsInSection:section].top;
    for (NSUInteger column = 0; column < numberOfColumns; column++) {
        [self appendHeight:topInset toColumn:column inSection:section];
    }
    
    CGSize headerSize = [self headerReferenceSizeInSection:section];
    if (headerSize.height > 0) {
        UICollectionViewLayoutAttributes *headerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
        headerAttributes.frame = CGRectMake(0, reverseTetrisPoint, headerSize.width, headerSize.height);
        for (NSUInteger column = 0; column < numberOfColumns; column++) {
            // This implicitly adds to the reverseTetrisPoint
            [self appendHeight:headerSize.height toColumn:column inSection:section];
        }
        self.headerAttributes[section] = headerAttributes;
    }
    
    CGFloat leftInset = [self sectionInsetsInSection:section].left;
    CGFloat rightInset = [self sectionInsetsInSection:section].right;
    CGFloat cellContentAreaWidth = CGRectGetWidth(self.collectionView.frame) - (leftInset + rightInset);
    CGFloat numberOfGutters = numberOfColumns - 1;
    CGFloat singleGutterWidth = [self minimumInteritemSpacingInSection:section];
    CGFloat totalGutterWidth = singleGutterWidth * numberOfGutters;
    CGFloat minimumLineSpacing = [self minimumLineSpacingInSection:section];
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
    CGFloat itemWidth = floorf((cellContentAreaWidth - totalGutterWidth) / numberOfColumns);
    
    for (NSUInteger item = 0; item < itemCount; item++) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        NSUInteger shortestColumnIndex = [self shortestColumnInSection:section];
        CGFloat xOffset = leftInset + ((itemWidth + singleGutterWidth) * shortestColumnIndex);
        CGFloat yOffset = reverseTetrisPoint + [self shortestColumnHeightInSection:section].floatValue;
        
        CGFloat itemHeight = [self estimatedItemHeightForItemAtIndexPath:indexPath];
        
        if (self.preferredItemAttributes[indexPath]) {
            UICollectionViewLayoutAttributes *preferredAttributes = self.preferredItemAttributes[indexPath];
            itemHeight = preferredAttributes.size.height;
        }
        
        UICollectionViewLayoutAttributes *cellAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        cellAttributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight);
        
        [self appendHeight:(ceilf(CGRectGetHeight(cellAttributes.frame) + minimumLineSpacing)) toColumn:shortestColumnIndex inSection:section];
        [self.allItemAttributes setObject:cellAttributes forKey:indexPath];
    }
    
    CGFloat bottomInset = [self sectionInsetsInSection:section].bottom;
    for (NSUInteger column = 0; column < numberOfColumns; column++) {
        [self appendHeight:bottomInset toColumn:column inSection:section];
    }
    
    reverseTetrisPoint = [[[self allSectionHeights] valueForKeyPath:@"@sum.floatValue"] floatValue];
    
    CGSize footerSize = [self footerReferenceSizeInSection:section];
    if (footerSize.height > 0) {
        UICollectionViewLayoutAttributes *footerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
        footerAttributes.frame = CGRectMake(0, reverseTetrisPoint, footerSize.width, footerSize.height);
        
        for (NSUInteger column = 0; column < numberOfColumns; column++) {
            [self appendHeight:footerSize.height toColumn:column inSection:section];
        }
        self.footerAttributes[section] = footerAttributes;
    }
    
}



#pragma mark -
#pragma mark Provide Layout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *layoutAttributesForElementsInRect = [NSMutableArray array];
    
    [self.allItemAttributes.allValues enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
        if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
            [layoutAttributesForElementsInRect addObject:layoutAttributes];
        }
    }];
    
    [self.headerAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
        if (![layoutAttributes isEqual:[NSNull null]]) {
            if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                [layoutAttributesForElementsInRect addObject:layoutAttributes];
            }
        }
    }];
    
    [self.footerAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
        if (![layoutAttributes isEqual:[NSNull null]]) {
            if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                [layoutAttributesForElementsInRect addObject:layoutAttributes];
            }
        }
    }];
    
    return layoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.allItemAttributes[indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        return self.headerAttributes[indexPath.section];
    }
    
    if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        return self.footerAttributes[indexPath.section];
    }
    
    return nil;
}

- (CGSize)collectionViewContentSize
{
    CGSize contentSize = self.collectionView.bounds.size;
    contentSize.height = [[[self allSectionHeights] valueForKeyPath:@"@sum.floatValue"] floatValue];
    return contentSize;
}



#pragma mark -
#pragma mark Calculation and Utility

- (NSArray *)columnHeightsInSection:(NSUInteger)section
{
    return self.columnHeights[section];
}

- (NSNumber *)shortestColumnHeightInSection:(NSInteger)section
{
    return [[self columnHeightsInSection:section] valueForKeyPath:@"@min.floatValue"];
}

- (NSUInteger)shortestColumnInSection:(NSInteger)section
{
    NSNumber *shortestColumnHeight = [self shortestColumnHeightInSection:section];
    return [[self columnHeightsInSection:section] indexOfObject:shortestColumnHeight];
}

- (NSNumber *)largestColumnHeightInSection:(NSInteger)section
{
    return [[self columnHeightsInSection:section] valueForKeyPath:@"@max.floatValue"];
}

- (NSUInteger)largestColumnInSection:(NSInteger)section
{
    NSNumber *largestColumnHeight = [self largestColumnHeightInSection:section];
    return [[self columnHeightsInSection:section] indexOfObject:largestColumnHeight];
}

- (void)appendHeight:(CGFloat)height toColumn:(NSUInteger)column inSection:(NSUInteger)section
{
    CGFloat existing = [self.columnHeights[section][column] floatValue];
    CGFloat updated = existing + height;
    self.columnHeights[section][column] = @(updated);
}

- (NSNumber *)sectionHeight:(NSUInteger)section
{
    CGFloat sectionHeight = [[self largestColumnHeightInSection:section] floatValue];
    return @(sectionHeight);
}

- (NSArray *)allSectionHeights
{
    NSMutableArray *sectionHeights = [NSMutableArray arrayWithCapacity:self.numberOfSections];
    for (NSUInteger section = 0; section < self.numberOfSections; section++) {
        [sectionHeights addObject:[self sectionHeight:section]];
    }
    return sectionHeights;
}



#pragma mark -
#pragma mark Self Sizing Cells

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes
{
    if (preferredAttributes.representedElementCategory == UICollectionElementCategoryCell) {
        self.preferredItemAttributes[preferredAttributes.indexPath] = preferredAttributes;
    }
    
    return YES;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes
{
    UICollectionViewLayoutInvalidationContext *context = [super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
    [context invalidateEverything];
    return context;
}



#pragma mark -
#pragma mark Invalidation

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return !(CGSizeEqualToSize(newBounds.size, self.collectionView.frame.size));
}

@end