#import "WMFCVLInfo.h"
#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"
#import "WMFCVLInvalidationContext.h"
#import "WMFColumnarCollectionViewLayout.h"
#import "WMFCVLMetrics.h"
#import "WMFCVLAttributes.h"

@interface WMFCVLInfo ()
@property (nonatomic, strong, nonnull) NSMutableArray <WMFCVLColumn *> *columns;
@property (nonatomic, strong, nonnull) NSMutableArray <WMFCVLSection *> *sections;
@property (nonatomic, copy, nonnull) WMFCVLMetrics *metrics;
@end

@implementation WMFCVLInfo

- (instancetype)initWithMetrics:(WMFCVLMetrics *)metrics {
    self = [super init];
    if (self) {
        self.metrics = metrics;
        [self resetColumnsAndSections];
    }
    return self;
}

- (void)resetColumnsAndSections {
    self.columns = [NSMutableArray arrayWithCapacity:self.metrics.numberOfColumns];
    for (NSInteger i = 0; i < self.metrics.numberOfColumns; i++) {
        WMFCVLColumn *column = [WMFCVLColumn new];
        column.index = i;
        column.info = self;
        [_columns addObject:column];
    }
    self.sections = [NSMutableArray array];
}

- (id)copyWithZone:(NSZone *)zone {
    WMFCVLInfo *copy = [[WMFCVLInfo allocWithZone:zone] initWithMetrics:self.metrics];
    copy.sections = [[NSMutableArray allocWithZone:zone] initWithArray:self.sections copyItems:YES];
    copy.columns = [[NSMutableArray allocWithZone:zone] initWithArray:self.columns copyItems:YES];
    for (WMFCVLColumn *column in copy.columns) {
        column.info = copy;
        [column enumerateSectionsWithBlock:^(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
            section.column = column;
        }];
    }
    copy.boundsSize = self.boundsSize;
    copy.contentSize = self.contentSize;
    copy.metrics = self.metrics;
    return copy;
}

- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.sections enumerateObjectsUsingBlock:block];
}

- (void)enumerateColumnsWithBlock:(nonnull void(^)(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.columns enumerateObjectsUsingBlock:block];
}

- (nullable WMFCVLAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger sectionIndex = indexPath.section;
    
    if (sectionIndex < 0 || sectionIndex >= self.sections.count) {
        return nil;
    }
    
    WMFCVLSection *section = self.sections[sectionIndex];
    NSInteger itemIndex = indexPath.item;
    if (itemIndex < 0 || itemIndex >= section.items.count) {
        return nil;
    }
    
    WMFCVLAttributes *attributes = section.items[itemIndex];
    assert(attributes != nil);
    return attributes;
}

- (nullable WMFCVLAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    NSInteger sectionIndex = indexPath.section;
    if (sectionIndex < 0 || sectionIndex >= self.sections.count) {
        return nil;
    }
    
    WMFCVLSection *section = self.sections[sectionIndex];
    
    WMFCVLAttributes *attributes = nil;
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        NSInteger itemIndex = indexPath.item;
        if (itemIndex < 0 || itemIndex >= section.headers.count) {
            return nil;
        }
        attributes = section.headers[itemIndex];
    } else if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        NSInteger itemIndex = indexPath.item;
        if (itemIndex < 0 || itemIndex >= section.footers.count) {
            return nil;
        }
        attributes = section.footers[itemIndex];
    }
    
    assert(attributes != nil);
    return attributes;
}

- (void)updateContentSize {
    __block CGSize newSize = self.boundsSize;
    newSize.height = 0;
    [self enumerateColumnsWithBlock:^(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat columnHeight = column.height;
        if (columnHeight > newSize.height) {
            newSize.height = columnHeight;
        }
    }];
    self.contentSize = newSize;
}

- (void)updateContentSizeWithInvalidationContext:(WMFCVLInvalidationContext *)context {
    CGSize oldContentSize = self.contentSize;
    
    [self updateContentSize];
    
    CGSize contentSizeAdjustment = CGSizeMake(self.contentSize.width - oldContentSize.width, self.contentSize.height - oldContentSize.height);
    context.contentSizeAdjustment = contentSizeAdjustment;
}

- (void)updateWithInvalidationContext:(nonnull WMFCVLInvalidationContext *)context delegate:(id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView {
    if (context.boundsDidChange) {
        [self resetColumnsAndSections];
        [self layoutForBoundsSize:context.newBounds.size withDelegate:delegate collectionView:collectionView invalidationContext:context];
    } else if (context.originalLayoutAttributes && context.preferredLayoutAttributes) {
        UICollectionViewLayoutAttributes *originalAttributes = context.originalLayoutAttributes;
        UICollectionViewLayoutAttributes *preferredAttributes = context.preferredLayoutAttributes;
        NSIndexPath *indexPath = originalAttributes.indexPath;
        
        WMFCVLSection *invalidatedSection = self.sections[indexPath.section];
        WMFCVLColumn *invalidatedColumn = invalidatedSection.column;
        
        CGSize sizeToSet = preferredAttributes.frame.size;
        sizeToSet.width = invalidatedColumn.width;
        
        if (originalAttributes.representedElementCategory == UICollectionElementCategoryCell) {
            [invalidatedColumn setSize:sizeToSet forItemAtIndexPath:indexPath invalidationContext:context];
        } else if ([originalAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            [invalidatedColumn setSize:sizeToSet forHeaderAtIndexPath:indexPath invalidationContext:context];
        } else if ([originalAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            [invalidatedColumn setSize:sizeToSet forFooterAtIndexPath:indexPath invalidationContext:context];
        }

        [self updateContentSizeWithInvalidationContext:context];
        
        if (CGRectGetMaxY(originalAttributes.frame) < collectionView.contentOffset.y) {
            context.contentOffsetAdjustment = CGPointMake(0, context.contentSizeAdjustment.height);
        }
    }
}

- (void)layoutForBoundsSize:(CGSize)size withDelegate:(id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView invalidationContext:(nullable WMFCVLInvalidationContext *)context {
    NSUInteger numberOfColumns = self.metrics.numberOfColumns;
    UIEdgeInsets contentInsets = self.metrics.contentInsets;
    UIEdgeInsets sectionInsets = self.metrics.sectionInsets;
    CGFloat interColumnSpacing = self.metrics.interColumnSpacing;
    CGFloat interItemSpacing = self.metrics.interItemSpacing;
    CGFloat interSectionSpacing = self.metrics.interSectionSpacing;
    NSArray *columnWeights = self.metrics.columnWeights;
    NSInteger numberOfSections = [collectionView.dataSource numberOfSectionsInCollectionView:collectionView];
    
    CGFloat availableWidth = size.width - contentInsets.left - contentInsets.right - ((numberOfColumns - 1) * interColumnSpacing);
    
    CGFloat baselineColumnWidth = floor(availableWidth/numberOfColumns);
    
    self.boundsSize = size;
    
    __block NSInteger currentColumnIndex = 0;
    __block WMFCVLColumn *currentColumn = self.columns[currentColumnIndex];
    
    NSMutableArray *invalidatedItemIndexPaths = [NSMutableArray array];
    NSMutableArray *invalidatedHeaderIndexPaths = [NSMutableArray array];
    NSMutableArray *invalidatedFooterIndexPaths = [NSMutableArray array];
    
    assert([_sections count] == 0);
    
    for (NSUInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
        WMFCVLSection *section = [WMFCVLSection sectionWithIndex:sectionIndex];
        [_sections addObject:section];

        currentColumn.width = [columnWeights[currentColumnIndex] doubleValue]*baselineColumnWidth;
        CGFloat columnWidth = currentColumn.width;
        
        CGFloat x = contentInsets.left;
        for (NSInteger i = 0; i < currentColumnIndex; i++) {
            x += [columnWeights[i] doubleValue] * baselineColumnWidth + interColumnSpacing;
        }
        
        if (sectionIndex == 0) {
            currentColumn.height += contentInsets.top;
        } else {
            currentColumn.height += interSectionSpacing;
        }
        CGFloat y = currentColumn.height;
        CGPoint sectionOrigin = CGPointMake(x, y);
        
        [currentColumn addSection:section];
        
        CGFloat sectionHeight = 0;
        
        CGFloat headerHeight = [delegate collectionView:collectionView estimatedHeightForHeaderInSection:sectionIndex forColumnWidth:columnWidth];
    
        NSIndexPath *supplementaryViewIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
        [invalidatedHeaderIndexPaths addObject:supplementaryViewIndexPath];
        [invalidatedFooterIndexPaths addObject:supplementaryViewIndexPath];
        
        WMFCVLAttributes *headerAttributes = (WMFCVLAttributes *)[WMFCVLAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:supplementaryViewIndexPath];
        if (headerAttributes != nil) {
            headerAttributes.frame = CGRectMake(x, y, columnWidth, headerHeight);
            [section addHeader:headerAttributes];
        }
        
        sectionHeight += headerHeight;
        y += headerHeight;
        
        CGFloat itemX = x + sectionInsets.left;
        CGFloat itemWidth = columnWidth - sectionInsets.left - sectionInsets.right;
        for (NSInteger item = 0; item < [collectionView.dataSource collectionView:collectionView numberOfItemsInSection:sectionIndex]; item++) {
            if (item == 0) {
                y += sectionInsets.top;
            } else {
                y += interItemSpacing;
            }
            CGFloat itemHeight = [delegate collectionView:collectionView estimatedHeightForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:sectionIndex] forColumnWidth:columnWidth];
            
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:sectionIndex];
            [invalidatedItemIndexPaths addObject:itemIndexPath];
            WMFCVLAttributes *itemAttributes = (WMFCVLAttributes *)[WMFCVLAttributes layoutAttributesForCellWithIndexPath:itemIndexPath];
            if (itemAttributes != nil) {
                itemAttributes.frame = CGRectMake(itemX, y, itemWidth, itemHeight);
                [section addItem:itemAttributes];
            }
            assert(itemHeight > 0);
            sectionHeight += itemHeight;
            y += itemHeight;
        }
        
        sectionHeight += sectionInsets.bottom;
        y += sectionInsets.bottom;
        
        CGFloat footerHeight = [delegate collectionView:collectionView estimatedHeightForFooterInSection:sectionIndex forColumnWidth:columnWidth];
        WMFCVLAttributes *footerAttributes = (WMFCVLAttributes *)[WMFCVLAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:supplementaryViewIndexPath];
        if (footerAttributes != nil) {
            footerAttributes.frame = CGRectMake(x, y, columnWidth, footerHeight);
            [section addFooter:footerAttributes];
        }
        
        sectionHeight += footerHeight;
        y+= footerHeight;
        
        section.frame = (CGRect){sectionOrigin,  CGSizeMake(columnWidth, sectionHeight)};
        
        currentColumn.height = currentColumn.height + sectionHeight;
        
        __block CGFloat shortestColumnHeight = CGFLOAT_MAX;
        [self enumerateColumnsWithBlock:^(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat columnHeight = column.height;
            if (columnHeight < shortestColumnHeight) { //switch to the shortest column
                currentColumnIndex = idx;
                currentColumn = column;
                shortestColumnHeight = columnHeight;
            }
        }];
    }
    
    [self enumerateColumnsWithBlock:^(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
        column.height += contentInsets.bottom;
    }];
    
    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:invalidatedHeaderIndexPaths];
    [context invalidateItemsAtIndexPaths:invalidatedItemIndexPaths];
    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionFooter atIndexPaths:invalidatedFooterIndexPaths];
    [self updateContentSizeWithInvalidationContext:context];
}

- (void)layoutForBoundsSize:(CGSize)size withDelegate:(id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView {
    [self layoutForBoundsSize:size withDelegate:delegate collectionView:collectionView invalidationContext:nil];
}

@end
