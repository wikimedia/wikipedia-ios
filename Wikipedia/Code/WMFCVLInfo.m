#import "WMFCVLInfo.h"
#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"
#import "WMFCVLInvalidationContext.h"
#import "WMFColumnarCollectionViewLayout.h"
#import "WMFCVLMetrics.h"
#import "WMFCVLAttributes.h"

@interface WMFCVLInfo ()
@property (nonatomic, strong, nullable) NSMutableArray<WMFCVLColumn *> *columns;
@property (nonatomic, strong, nullable) NSMutableArray<WMFCVLSection *> *sections;
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

    copy.columns = columns;
    copy.contentSize = self.contentSize;
    return copy;
}

- (void)resetColumns {
    self.columns = nil;
    [self enumerateSectionsWithBlock:^(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        section.columnIndex = NSNotFound;
    }];
}

- (void)resetSections {
    self.sections = nil;
}

- (void)reset {
    [self resetColumns];
    [self resetSections];
}

- (void)enumerateSectionsWithBlock:(nonnull void (^)(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop))block {
    [self.sections enumerateObjectsUsingBlock:block];
}

- (void)enumerateColumnsWithBlock:(nonnull void (^)(WMFCVLColumn *_Nonnull column, NSUInteger idx, BOOL *_Nonnull stop))block {
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
    [self enumerateColumnsWithBlock:^(WMFCVLColumn *_Nonnull column, NSUInteger idx, BOOL *_Nonnull stop) {
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

- (void)updateWithMetrics:(WMFCVLMetrics *)metrics invalidationContext:(nullable WMFCVLInvalidationContext *)context delegate:(id<WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView {
    if (delegate == nil) {
        return;
    }
    if (collectionView == nil) {
        return;
    }
    if (context.boundsDidChange) {
        [self resetColumns];
        [self layoutWithMetrics:metrics delegate:delegate collectionView:collectionView invalidationContext:nil];
    } else if (context.originalLayoutAttributes && context.preferredLayoutAttributes) {
        UICollectionViewLayoutAttributes *originalAttributes = context.originalLayoutAttributes;
        UICollectionViewLayoutAttributes *preferredAttributes = context.preferredLayoutAttributes;
        NSIndexPath *indexPath = originalAttributes.indexPath;

        NSInteger sectionIndex = indexPath.section;
        if (sectionIndex >= self.sections.count) {
            [self layoutWithMetrics:metrics delegate:delegate collectionView:collectionView invalidationContext:nil];
            return;
        }
        NSInteger invalidatedColumnIndex = self.sections[sectionIndex].columnIndex;
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
        if (!context) {
            [self reset];
        }
        [self layoutWithMetrics:metrics delegate:delegate collectionView:collectionView invalidationContext:nil]; //context is intentionally nil - apparently .invalidateEverything and .invalidateDataSourceCounts contexts shouldn't be updated
    }
}

- (void)layoutWithMetrics:(nonnull WMFCVLMetrics *)metrics delegate:(id<WMFColumnarCollectionViewLayoutDelegate>)delegate collectionView:(UICollectionView *)collectionView invalidationContext:(nullable WMFCVLInvalidationContext *)context {

    NSInteger numberOfSections = [collectionView.dataSource numberOfSectionsInCollectionView:collectionView];
    UIEdgeInsets contentInsets = metrics.contentInsets;
    UIEdgeInsets sectionInsets = metrics.sectionInsets;
    CGFloat interColumnSpacing = metrics.interColumnSpacing;
    CGFloat interItemSpacing = metrics.interItemSpacing;
    CGFloat interSectionSpacing = metrics.interSectionSpacing;
    NSArray *columnWeights = metrics.columnWeights;
    CGSize size = metrics.boundsSize;
    NSInteger numberOfColumns = metrics.numberOfColumns;
    NSInteger widestColumnIndex = 0;
    CGFloat widestColumnWidth = 0;

    if (self.sections == nil) {
        self.sections = [NSMutableArray arrayWithCapacity:numberOfSections];
    }

    if (self.columns == nil) {
        CGFloat availableWidth = size.width - contentInsets.left - contentInsets.right - ((numberOfColumns - 1) * interColumnSpacing);

        CGFloat baselineColumnWidth = floor(availableWidth / numberOfColumns);
        self.columns = [NSMutableArray arrayWithCapacity:numberOfColumns];
        CGFloat x = contentInsets.left;
        for (NSInteger i = 0; i < numberOfColumns; i++) {
            WMFCVLColumn *column = [WMFCVLColumn new];
            CGFloat columnWeight = [columnWeights[i] doubleValue];
            CGFloat columnWidth = round(columnWeight * baselineColumnWidth);
            if (columnWidth > widestColumnWidth) {
                widestColumnWidth = columnWidth;
                widestColumnIndex = i;
            }
            CGRect columnFrame = CGRectMake(x, 0, columnWidth, 0);
            column.frame = columnFrame;
            column.index = i;
            column.info = self;
            [_columns addObject:column];
            x += columnWidth + interColumnSpacing;
        }
    } else {
        NSInteger i = 0;
        for (WMFCVLColumn *column in self.columns) {
            CGRect newFrame = column.frame;
            newFrame.size.height = 0;
            CGFloat columnWidth = newFrame.size.width;
            if (columnWidth > widestColumnWidth) {
                widestColumnWidth = columnWidth;
                widestColumnIndex = i;
            }
            column.frame = newFrame;
#if DEBUG
            CGFloat availableWidth = size.width - contentInsets.left - contentInsets.right - ((numberOfColumns - 1) * interColumnSpacing);

            CGFloat baselineColumnWidth = round(availableWidth / numberOfColumns);
            CGFloat columnWidthToCheck = round([columnWeights[column.index] doubleValue] * baselineColumnWidth);
            assert(ABS(column.frame.size.width - columnWidthToCheck) < 1);
#endif
            i++;
        }
    }

    NSMutableArray *invalidatedItemIndexPaths = [NSMutableArray array];
    NSMutableArray *invalidatedHeaderIndexPaths = [NSMutableArray array];
    NSMutableArray *invalidatedFooterIndexPaths = [NSMutableArray array];

    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
        WMFCVLColumn *shortestColumn = nil;
        CGFloat shortestColumnHeight = CGFLOAT_MAX;
        for (NSInteger columnIndex = 0; columnIndex < numberOfColumns; columnIndex++) {
            WMFCVLColumn *column = self.columns[columnIndex];
            CGFloat columnHeight = column.frame.size.height;
            if (columnHeight < shortestColumnHeight) {
                shortestColumn = column;
                shortestColumnHeight = columnHeight;
            }
        }

        WMFCVLSection *section = nil;

        NSInteger currentColumnIndex = numberOfColumns == 1 ? 0 : [delegate collectionView:collectionView prefersWiderColumnForSectionAtIndex:sectionIndex] ? widestColumnIndex : shortestColumn.index;
        WMFCVLColumn *column = self.columns[currentColumnIndex];

        if (sectionIndex >= [_sections count]) {
            section = [WMFCVLSection sectionWithIndex:sectionIndex];
            [_sections addObject:section];
            [column addSection:section];
        } else {
            section = _sections[sectionIndex];
            if (section.columnIndex == NSNotFound) {
                [column addSection:section];
            } else {
                currentColumnIndex = section.columnIndex;
            }
            column = self.columns[currentColumnIndex];
            if (![column containsSectionWithSectionIndex:sectionIndex]) {
                if (section.columnIndex != NSNotFound && section.columnIndex < _columns.count) {
                    [_columns[section.columnIndex] removeSection:section];
                }
                [column addSection:section];
            }
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

        CGFloat sectionHeight = 0;

        NSIndexPath *supplementaryViewIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];

        __block CGFloat headerHeight = 0;
        BOOL didCreateOrUpdate = [section addOrUpdateHeaderAtIndex:0
                                                 withFrameProvider:^CGRect(BOOL wasCreated, CGRect existingFrame, WMFCVLAttributes *attributes) {
                                                     if (wasCreated || section.needsToRecalculateEstimatedLayout) {
                                                         headerHeight = [delegate collectionView:collectionView estimatedHeightForHeaderInSection:sectionIndex forColumnWidth:columnWidth];
                                                         return CGRectMake(x, y, columnWidth, headerHeight);
                                                     } else {
                                                         headerHeight = existingFrame.size.height;
                                                         return CGRectMake(x, y, columnWidth, headerHeight);
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
            BOOL didCreateOrUpdate = [section addOrUpdateItemAtIndex:item
                                                   withFrameProvider:^CGRect(BOOL wasCreated, CGRect existingFrame, WMFCVLAttributes *attributes) {
                                                       if (wasCreated || section.needsToRecalculateEstimatedLayout) {
                                                           WMFLayoutEstimate estimate = [delegate collectionView:collectionView estimatedHeightForItemAtIndexPath:itemIndexPath forColumnWidth:columnWidth];
                                                           attributes.precalculated = estimate.precalculated;
                                                           itemHeight = estimate.height;
                                                           return CGRectMake(itemX, y, itemWidth, itemHeight);
                                                       } else {
                                                           itemHeight = existingFrame.size.height;
                                                           return CGRectMake(itemX, y, itemWidth, itemHeight);
                                                       }
                                                   }];
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
        didCreateOrUpdate = [section addOrUpdateFooterAtIndex:0
                                            withFrameProvider:^CGRect(BOOL wasCreated, CGRect existingFrame, WMFCVLAttributes *attributes) {
                                                if (wasCreated || section.needsToRecalculateEstimatedLayout) {
                                                    footerHeight = [delegate collectionView:collectionView estimatedHeightForFooterInSection:sectionIndex forColumnWidth:columnWidth];
                                                    return CGRectMake(x, y, columnWidth, footerHeight);
                                                } else {
                                                    footerHeight = existingFrame.size.height;
                                                    return CGRectMake(x, y, columnWidth, footerHeight);
                                                }
                                            }];
        if (didCreateOrUpdate) {
            [invalidatedFooterIndexPaths addObject:supplementaryViewIndexPath];
        }

        assert(section.footers.count == 1);

        sectionHeight += footerHeight;

        section.frame = (CGRect){sectionOrigin, CGSizeMake(columnWidth, sectionHeight)};

        [column updateHeightWithDelta:sectionHeight];

        section.needsToRecalculateEstimatedLayout = NO;
    }

    if (_sections.count > numberOfSections) {
        NSRange invalidSectionRange = NSMakeRange(numberOfSections, _sections.count - numberOfSections);
        [_sections removeObjectsInRange:invalidSectionRange];
        for (WMFCVLColumn *column in self.columns) {
            [column removeSectionsWithSectionIndexesInRange:invalidSectionRange];
        }
    }

    assert(_sections.count == numberOfSections);

    [self enumerateColumnsWithBlock:^(WMFCVLColumn *_Nonnull column, NSUInteger idx, BOOL *_Nonnull stop) {
        [column updateHeightWithDelta:contentInsets.bottom];
    }];

    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:invalidatedHeaderIndexPaths];
    [context invalidateItemsAtIndexPaths:invalidatedItemIndexPaths];
    [context invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionFooter atIndexPaths:invalidatedFooterIndexPaths];

    BOOL needsAnotherLayoutPass = NO;

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

        WMFCVLSection *lastSectionInTallestColumn = tallestColumn.lastSection;

        while (lastSectionInTallestColumn && lastSectionInTallestColumn.frame.origin.y > shortestColumn.frame.size.height) {
            needsAnotherLayoutPass = YES;
            [tallestColumn removeSection:lastSectionInTallestColumn];
            [shortestColumn addSection:lastSectionInTallestColumn];

            lastSectionInTallestColumn.columnIndex = shortestColumn.index;
            lastSectionInTallestColumn.needsToRecalculateEstimatedLayout = YES;

            CGFloat heightDelta = lastSectionInTallestColumn.frame.size.height + interSectionSpacing;
            [tallestColumn updateHeightWithDelta:-1 * heightDelta];
            [shortestColumn updateHeightWithDelta:heightDelta]; // this is potentially error prone - the height will be different for different width columns

            lastSectionInTallestColumn = tallestColumn.lastSection;
        }
    }

    if (needsAnotherLayoutPass) {
        WMFCVLMetrics *newMetrics = [metrics copy];
        newMetrics.shouldMatchColumnHeights = NO;
        [self layoutWithMetrics:newMetrics delegate:delegate collectionView:collectionView invalidationContext:context];
    } else {
        [self updateContentSizeWithMetrics:metrics invalidationContext:context];
#if DEBUG
        NSArray *indexes = [self.columns valueForKey:@"sectionIndexes"];
        for (NSIndexSet *set in indexes) {
            for (NSIndexSet *otherSet in indexes) {
                if (set != otherSet) {
                    [set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *_Nonnull stop) {
                        assert(![otherSet containsIndex:idx]);
                    }];
                }
            }
        }

        for (WMFCVLColumn *column in self.columns) {
            assert(column.frame.origin.x < self.contentSize.width);
            [column enumerateSectionsWithBlock:^(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
                assert(section.frame.origin.x == column.frame.origin.x);
                [section enumerateLayoutAttributesWithBlock:^(WMFCVLAttributes *_Nonnull layoutAttributes, BOOL *_Nonnull stop) {
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
