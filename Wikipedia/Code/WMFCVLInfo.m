#import "WMFCVLInfo.h"
#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"
#import "WMFCVLInvalidationContext.h"
#import "WMFColumnarCollectionViewLayout.h"
#import "WMFCVLMetrics.h"
#import "WMFCVLAttributes.h"

@interface WMFCVLInfo ()
@property (nonatomic, strong, nullable) NSMutableArray <WMFCVLColumn *> *columns;
@property (nonatomic, strong, nullable) NSMutableArray <WMFCVLSection *> *sections;
@property (nonatomic, strong, nonnull) NSMutableArray <NSNumber *> *columnIndexBySectionIndex;
@end

@implementation WMFCVLInfo

- (id)copyWithZone:(NSZone *)zone {
    WMFCVLInfo *copy = [[WMFCVLInfo allocWithZone:zone] init];
    copy.sections = [[NSMutableArray allocWithZone:zone] initWithArray:self.sections copyItems:YES];
    
    NSMutableArray *columns = [[NSMutableArray allocWithZone:zone] initWithCapacity:self.columns.count];
    for (WMFCVLColumn *column in self.columns) {
        WMFCVLColumn *newColumn = [column copy];
        newColumn.info = copy;
        [columns addObject:newColumn];
    }
    
    copy.columnIndexBySectionIndex = [self.columnIndexBySectionIndex mutableCopy];
    copy.columns = columns;
    copy.contentSize = self.contentSize;
    return copy;
}

- (void)reset {
    self.columns = nil;
    self.sections = nil;
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

- (void)updateContentSizeWithMetrics:(WMFCVLMetrics *)metrics {
    __block CGSize newSize = metrics.boundsSize;
    newSize.height = 0;
    [self enumerateColumnsWithBlock:^(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat columnHeight = column.frame.size.height;
        if (columnHeight > newSize.height) {
            newSize.height = columnHeight;
        }
    }];
    self.contentSize = newSize;
}

- (void)updateContentSizeWithMetrics:(WMFCVLMetrics *)metrics invalidationContext:(WMFCVLInvalidationContext *)context {
    CGSize oldContentSize = self.contentSize;
    
    [self updateContentSizeWithMetrics:metrics];
    
    CGSize contentSizeAdjustment = CGSizeMake(self.contentSize.width - oldContentSize.width, self.contentSize.height - oldContentSize.height);
    context.contentSizeAdjustment = contentSizeAdjustment;
}

- (void)updateWithMetrics:(WMFCVLMetrics *)metrics invalidationContext:(nullable WMFCVLInvalidationContext *)context delegate:(id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView {
    if (delegate == nil) {
        return;
    }
    if (collectionView == nil) {
        return;
    }
    if (context.boundsDidChange) {
        [self reset];
        [self layoutWithMetrics:metrics delegate:delegate collectionView:collectionView invalidationContext:context];
    } else if (context.originalLayoutAttributes && context.preferredLayoutAttributes) {
        UICollectionViewLayoutAttributes *originalAttributes = context.originalLayoutAttributes;
        UICollectionViewLayoutAttributes *preferredAttributes = context.preferredLayoutAttributes;
        NSIndexPath *indexPath = originalAttributes.indexPath;
        
        NSInteger sectionIndex = indexPath.section;
        NSInteger invalidatedColumnIndex = [self.columnIndexBySectionIndex[sectionIndex] integerValue];
        WMFCVLColumn *invalidatedColumn = self.columns[invalidatedColumnIndex];
        
        CGSize sizeToSet = preferredAttributes.frame.size;
        sizeToSet.width = invalidatedColumn.frame.size.width;
        
        if (originalAttributes.representedElementCategory == UICollectionElementCategoryCell) {
            [invalidatedColumn setSize:sizeToSet forItemAtIndexPath:indexPath invalidationContext:context];
        } else if ([originalAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            [invalidatedColumn setSize:sizeToSet forHeaderAtIndexPath:indexPath invalidationContext:context];
        } else if ([originalAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
            [invalidatedColumn setSize:sizeToSet forFooterAtIndexPath:indexPath invalidationContext:context];
        }
        [self updateContentSizeWithMetrics:metrics invalidationContext:context];
        
        if (self.columns.count == 1 && originalAttributes.frame.origin.y < collectionView.contentOffset.y) {
            context.contentOffsetAdjustment = CGPointMake(0, context.contentSizeAdjustment.height);
        }
    } else {
        if (context.invalidateEverything) {
            [self reset];
        }
        [self layoutWithMetrics:metrics delegate:delegate collectionView:collectionView invalidationContext:context];
    }
}

- (void)layoutWithMetrics:(nonnull WMFCVLMetrics *)metrics delegate:(id <WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView invalidationContext:(nullable WMFCVLInvalidationContext *)context {
    
    NSInteger numberOfSections = [collectionView.dataSource numberOfSectionsInCollectionView:collectionView];
    UIEdgeInsets contentInsets = metrics.contentInsets;
    UIEdgeInsets sectionInsets = metrics.sectionInsets;
    CGFloat interColumnSpacing = metrics.interColumnSpacing;
    CGFloat interItemSpacing =  metrics.interItemSpacing;
    CGFloat interSectionSpacing = metrics.interSectionSpacing;
    NSArray *columnWeights = metrics.columnWeights;
    CGSize size = metrics.boundsSize;
    NSInteger numberOfColumns = metrics.numberOfColumns;
    
    if (self.sections == nil) {
        self.sections = [NSMutableArray arrayWithCapacity:numberOfSections];
        self.columnIndexBySectionIndex = [NSMutableArray arrayWithCapacity:numberOfSections];
    }
    
    if (self.columns == nil) {
        CGFloat availableWidth = size.width - contentInsets.left - contentInsets.right - ((numberOfColumns - 1) * interColumnSpacing);
        
        CGFloat baselineColumnWidth = floor(availableWidth/numberOfColumns);
        self.columns = [NSMutableArray arrayWithCapacity:numberOfColumns];
        CGFloat x = contentInsets.left;
        for (NSInteger i = 0; i < numberOfColumns; i++) {
            WMFCVLColumn *column = [WMFCVLColumn new];
            CGFloat columnWidth = [columnWeights[i] doubleValue]*baselineColumnWidth;
            CGRect columnFrame = CGRectMake(x, 0, columnWidth, 0);
            column.frame = columnFrame;
            column.index = i;
            column.info = self;
            [_columns addObject:column];
            x += columnWidth + interColumnSpacing;
        }
    } else {
        for (WMFCVLColumn *column in self.columns) {
            CGRect newFrame = column.frame;
            newFrame.size.height = 0;
            column.frame = newFrame;
#if DEBUG
            CGFloat availableWidth = size.width - contentInsets.left - contentInsets.right - ((numberOfColumns - 1) * interColumnSpacing);
            
            CGFloat baselineColumnWidth = floor(availableWidth/numberOfColumns);
            CGFloat columnWidth = [columnWeights[column.index] doubleValue]*baselineColumnWidth;
            assert(column.frame.size.width == columnWidth);
#endif
        }
    }

    NSMutableArray *invalidatedItemIndexPaths = [NSMutableArray array];
    NSMutableArray *invalidatedHeaderIndexPaths = [NSMutableArray array];
    NSMutableArray *invalidatedFooterIndexPaths = [NSMutableArray array];

    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
        WMFCVLSection *section = nil;
        
        WMFCVLColumn *column = nil;
        if (sectionIndex >= [_sections count]) {
            NSInteger currentColumnIndex = numberOfColumns == 1 ? 0 : [delegate collectionView:collectionView prefersWiderColumnForSectionAtIndex:sectionIndex] ? 0 : 1;
            column = self.columns[currentColumnIndex];
            section = [WMFCVLSection sectionWithIndex:sectionIndex];
            [_sections addObject:section];
            [_columnIndexBySectionIndex addObject:@(currentColumnIndex)];
        } else {
            section = _sections[sectionIndex];
            NSInteger columnIndex = [_columnIndexBySectionIndex[sectionIndex] integerValue];
            column = _columns[columnIndex];
        }

        CGFloat columnWidth = column.frame.size.width;
        CGFloat x = column.frame.origin.x;
        
        if (sectionIndex == 0) {
            [column updateHeightWithDelta:contentInsets.top];
        } else {
            [column updateHeightWithDelta:interSectionSpacing];
        }
        CGFloat y = column.frame.size.height;
        CGPoint sectionOrigin = CGPointMake(x, y);
        
        if (![column containsSectionWithSectionIndex:sectionIndex]) {
            [column addSection:section];
        }
        
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
        
        [column updateHeightWithDelta:sectionHeight];
    }
    
    if (_sections.count > numberOfSections) {
        [_sections removeObjectsInRange:NSMakeRange(numberOfSections, _sections.count - numberOfSections)];
    }
    
    assert(_sections.count == numberOfSections);
    
    [self enumerateColumnsWithBlock:^(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop) {
        [column updateHeightWithDelta:contentInsets.bottom];
    }];
    
    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:invalidatedHeaderIndexPaths];
    [context invalidateItemsAtIndexPaths:invalidatedItemIndexPaths];
    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionFooter atIndexPaths:invalidatedFooterIndexPaths];
    
    NSInteger countOfColumns = self.columns.count;
    if (metrics.shouldMatchColumnHeights && countOfColumns > 1) {
        WMFCVLColumn *shortestColumn = nil;
        CGFloat shortestColumnHeight = CGFLOAT_MAX;
        WMFCVLColumn *tallestColumn = nil;
        CGFloat tallestColumnHeight = 0;
        for (NSInteger columnIndex = 0; columnIndex < countOfColumns; columnIndex++) {
            WMFCVLColumn *column = self.columns[columnIndex];
            CGFloat columnHeight = column.frame.size.height;
            if (columnHeight < shortestColumnHeight) {
                shortestColumn = column;
                shortestColumnHeight = columnHeight;
            }
            if (columnHeight > tallestColumnHeight) {
                tallestColumn = column;
                tallestColumnHeight = columnHeight;
            }
        }
        
        CGFloat deltaHeightLimit = size.height; //bounds size
        CGFloat heightDelta = tallestColumnHeight - shortestColumnHeight;
        
        if (heightDelta > deltaHeightLimit) {
            while (heightDelta > deltaHeightLimit && tallestColumn) {
                NSInteger sectionIndex = [tallestColumn removeLastSection];
                _columnIndexBySectionIndex[sectionIndex] = @(shortestColumn.index);
                heightDelta -= self.sections[sectionIndex].frame.size.height;
                
            }
            
            self.columns = nil;
            WMFCVLMetrics *newMetrics = [metrics copy];
            newMetrics.shouldMatchColumnHeights = NO;
            [self layoutWithMetrics:newMetrics delegate:delegate collectionView:collectionView invalidationContext:context];
        }
    } else {
        [self updateContentSizeWithMetrics:metrics invalidationContext:context];
#if DEBUG
        NSArray *indexes = [self.columns valueForKey:@"sectionIndexes"];
        for (NSIndexSet *set in indexes) {
            for (NSIndexSet *otherSet in indexes) {
                if (set != otherSet) {
                    [set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        assert(![otherSet containsIndex:idx]);
                    }];
                }
            }
        }
        
        for (WMFCVLColumn *column in self.columns) {
            assert(column.frame.origin.x < self.contentSize.width);
            [column enumerateSectionsWithBlock:^(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
                assert(section.frame.origin.x == column.frame.origin.x);
                [section enumerateLayoutAttributesWithBlock:^(WMFCVLAttributes * _Nonnull layoutAttributes, BOOL * _Nonnull stop) {
                    assert(layoutAttributes.frame.origin.x == column.frame.origin.x);
                    assert(layoutAttributes.alpha == 1);
                    assert(layoutAttributes.hidden == NO);
                    assert(layoutAttributes.frame.origin.y < self.contentSize.height);
                }];
            }];
        }
        
#endif
    }
}

@end
