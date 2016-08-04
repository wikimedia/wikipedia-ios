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
@property (nonatomic, strong, nonnull) NSMutableArray <NSNumber *> *columnIndexBySectionIndex;
@property (nonatomic, copy, nonnull) WMFCVLMetrics *metrics;
@end

@implementation WMFCVLInfo

- (instancetype)initWithMetrics:(WMFCVLMetrics *)metrics {
    self = [super init];
    if (self) {
        self.metrics = metrics;
        [self resetColumns];
        [self resetSections];
    }
    return self;
}

- (void)resetColumns {
    self.columns = [NSMutableArray arrayWithCapacity:self.metrics.numberOfColumns];
    for (NSInteger i = 0; i < self.metrics.numberOfColumns; i++) {
        WMFCVLColumn *column = [WMFCVLColumn new];
        column.index = i;
        column.info = self;
        [_columns addObject:column];
    }
}

- (void)resetSections {
    self.sections = [NSMutableArray array];
    self.columnIndexBySectionIndex = [NSMutableArray array];
}

- (id)copyWithZone:(NSZone *)zone {
    WMFCVLInfo *copy = [[WMFCVLInfo allocWithZone:zone] initWithMetrics:self.metrics];
    copy.sections = [[NSMutableArray allocWithZone:zone] initWithArray:self.sections copyItems:YES];
    
    NSMutableArray *columns = [[NSMutableArray allocWithZone:zone] initWithCapacity:self.columns.count];
    for (WMFCVLColumn *column in self.columns) {
        WMFCVLColumn *newColumn = [column copy];
        newColumn.info = copy;
        [columns addObject:newColumn];
    }
    
    copy.columnIndexBySectionIndex = [self.columnIndexBySectionIndex mutableCopy];
    copy.columns = columns;
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

- (void)updateWithInvalidationContext:(nullable WMFCVLInvalidationContext *)context delegate:(id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView {
    if (delegate == nil) {
        return;
    }
    if (collectionView == nil) {
        return;
    }
    if (context.boundsDidChange) {
        [self resetSections];
        [self layoutForBoundsSize:context.newBounds.size withDelegate:delegate collectionView:collectionView invalidationContext:context];
    } else if (context.originalLayoutAttributes && context.preferredLayoutAttributes) {
        UICollectionViewLayoutAttributes *originalAttributes = context.originalLayoutAttributes;
        UICollectionViewLayoutAttributes *preferredAttributes = context.preferredLayoutAttributes;
        NSIndexPath *indexPath = originalAttributes.indexPath;
        
        NSInteger sectionIndex = indexPath.section;
        NSInteger invalidatedColumnIndex = [self.columnIndexBySectionIndex[sectionIndex] integerValue];
        WMFCVLColumn *invalidatedColumn = self.columns[invalidatedColumnIndex];
        
        CGSize sizeToSet = preferredAttributes.frame.size;
        sizeToSet.width = invalidatedColumn.width;
        
        if (originalAttributes.representedElementCategory == UICollectionElementCategoryCell) {
            [invalidatedColumn setSize:sizeToSet forItemAtIndexPath:indexPath invalidationContext:context];
        } else if ([originalAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            [invalidatedColumn setSize:sizeToSet forHeaderAtIndexPath:indexPath invalidationContext:context];
        } else if ([originalAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
            [invalidatedColumn setSize:sizeToSet forFooterAtIndexPath:indexPath invalidationContext:context];
        }
        [self updateContentSizeWithInvalidationContext:context];
        
        if (self.metrics.numberOfColumns == 1 && originalAttributes.frame.origin.y < collectionView.contentOffset.y) {
            context.contentOffsetAdjustment = CGPointMake(0, context.contentSizeAdjustment.height);
        }
    } else {
        self.boundsSize = collectionView.bounds.size;
        [self layoutForBoundsSize:self.boundsSize withDelegate:delegate collectionView:collectionView invalidationContext:context];
    }
}

- (void)layoutForBoundsSize:(CGSize)size withDelegate:(id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView invalidationContext:(nullable WMFCVLInvalidationContext *)context {
    [self resetColumns];
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

    for (NSUInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
        WMFCVLSection *section = nil;
        if (sectionIndex >= [_sections count]) {
            section = [WMFCVLSection sectionWithIndex:sectionIndex];
            [_sections addObject:section];
            [_columnIndexBySectionIndex addObject:@(currentColumnIndex)];
        } else {
            section = _sections[sectionIndex];
        }

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
        
        NSIndexPath *supplementaryViewIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
        
        __block CGFloat headerHeight = 0;
        BOOL didCreateOrUpdate = [section addOrUpdateHeaderAtIndex:0 withFrameProvider:^CGRect(BOOL wasCreated, CGRect existingFrame) {
            if (wasCreated) {
                headerHeight = [delegate collectionView:collectionView estimatedHeightForHeaderInSection:sectionIndex forColumnWidth:columnWidth];
                return CGRectMake(x, y, columnWidth, headerHeight);
            } else {
                CGRect newFrame = existingFrame;
                headerHeight = newFrame.size.height;
                newFrame.origin = CGPointMake(x, y);
                newFrame.size.width = columnWidth;
                return newFrame;
            }
        }];
        if (didCreateOrUpdate) {
            [invalidatedHeaderIndexPaths addObject:supplementaryViewIndexPath];
        }
        
        assert(section.headers.count == 1);
        
        sectionHeight += headerHeight;
        y += headerHeight;
        
        CGFloat itemX = x + sectionInsets.left;
        CGFloat itemWidth = columnWidth - sectionInsets.left - sectionInsets.right;
        NSInteger numberOfItems = [collectionView.dataSource collectionView:collectionView numberOfItemsInSection:sectionIndex];
        for (NSInteger item = 0; item < numberOfItems; item++) {
            if (item == 0) {
                y += sectionInsets.top;
            } else {
                y += interItemSpacing;
            }
            
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:sectionIndex];
            
            __block CGFloat itemHeight = 0;
            BOOL didCreateOrUpdate = [section addOrUpdateItemAtIndex:item withFrameProvider:^CGRect(BOOL wasCreated, CGRect existingFrame) {
                if (wasCreated) {
                     itemHeight = [delegate collectionView:collectionView estimatedHeightForItemAtIndexPath:itemIndexPath forColumnWidth:columnWidth];
                    return CGRectMake(itemX, y, itemWidth, itemHeight);
                } else {
                    CGRect newFrame = existingFrame;
                    itemHeight = existingFrame.size.height;
                    newFrame.origin = CGPointMake(itemX, y);
                    newFrame.size.width = itemWidth;
                    return newFrame;
                }}];
            if (didCreateOrUpdate) {
                [invalidatedItemIndexPaths addObject:itemIndexPath];
            }

            sectionHeight += itemHeight;
            y += itemHeight;
        }
        
        if (section.items.count > numberOfItems) {
            [section trimItemsToCount:numberOfItems];
        }
        
        assert(section.items.count == numberOfItems);
    
        sectionHeight += sectionInsets.bottom;
        y += sectionInsets.bottom;

        __block CGFloat footerHeight = 0;
        didCreateOrUpdate = [section addOrUpdateFooterAtIndex:0 withFrameProvider:^CGRect(BOOL wasCreated, CGRect existingFrame) {
            if (wasCreated) {
                footerHeight = [delegate collectionView:collectionView estimatedHeightForFooterInSection:sectionIndex forColumnWidth:columnWidth];
                return CGRectMake(x, y, columnWidth, footerHeight);
            } else {
                CGRect newFrame = existingFrame;
                footerHeight = newFrame.size.height;
                newFrame.origin = CGPointMake(x, y);
                newFrame.size.width = columnWidth;
                return newFrame;
            }
        }];
        if (didCreateOrUpdate) {
            [invalidatedFooterIndexPaths addObject:supplementaryViewIndexPath];
        }
        
        assert(section.footers.count == 1);
        
        sectionHeight += footerHeight;
        
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
    
    if (_sections.count > numberOfSections) {
        [_sections removeObjectsInRange:NSMakeRange(numberOfSections, _sections.count - numberOfSections)];
    }
    
    assert(_sections.count == numberOfSections);
    
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
