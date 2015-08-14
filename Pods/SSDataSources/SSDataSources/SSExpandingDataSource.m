//
//  SSExpandingDataSource.m
//  SSDataSources
//
//  Created by Jonathan Hersh on 11/26/14.
//  Copyright (c) 2014 Splinesoft. All rights reserved.
//

#import "SSDataSources.h"

@interface SSExpandingDataSource ()

- (void) performBatchUpdates:(void (^)(void))updates;

@end

@interface SSSection ()

@property (nonatomic, assign, readwrite, getter=isExpanded) BOOL expanded;

@end

@implementation SSExpandingDataSource

#pragma mark - Section/Index helpers

- (BOOL)isSectionExpandedAtIndex:(NSInteger)index {
    return [self sectionAtIndex:index].isExpanded;
}

- (BOOL)isItemVisibleAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.row < [self numberOfItemsInSection:indexPath.section]);
}

- (NSIndexSet *) expandedSectionIndexes {
    NSMutableIndexSet *expandedIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:
                                          NSMakeRange(0, [self numberOfSections])];
    
    [self.sections enumerateObjectsUsingBlock:^(SSSection *section,
                                                NSUInteger index,
                                                BOOL *stop) {
        if (!section.isExpanded) {
            [expandedIndexes removeIndex:index];
        }
    }];
    
    return [[NSIndexSet alloc] initWithIndexSet:expandedIndexes];
}

- (NSUInteger)numberOfCollapsedRowsInSection:(NSInteger)section {
    if (self.collapsedSectionCountBlock) {
        return self.collapsedSectionCountBlock([self sectionAtIndex:section],
                                               section);
    }
    
    return 0;
}

#pragma mark - Expanding Sections

- (void)toggleSectionAtIndex:(NSInteger)index {
    [self setSectionAtIndex:index
                   expanded:![self isSectionExpandedAtIndex:index]];
}

- (void)setSection:(SSSection *)section expanded:(BOOL)expanded {
    NSInteger sectionIndex = [self.sections indexOfObject:section];
    
    if (sectionIndex == NSNotFound) {
        return;
    }
    
    [self setSectionAtIndex:sectionIndex expanded:expanded];
}

- (void)setSectionAtIndex:(NSInteger)index expanded:(BOOL)expanded {
    BOOL isExpanded = [self isSectionExpandedAtIndex:index];
    
    if (isExpanded == expanded) {
        return;
    }
    
    SSSection *section = self.sections[index];
    
    NSUInteger targetRowCount = (expanded
                                 ? section.numberOfItems
                                 : [self numberOfCollapsedRowsInSection:index]);
    NSUInteger currentRowCount = [self numberOfItemsInSection:index];
    
    section.expanded = expanded;
    
    if (expanded) {
        [self insertCellsAtIndexPaths:
         [self.class indexPathArrayWithRange:NSMakeRange(currentRowCount, targetRowCount - currentRowCount)
                                   inSection:index]];
    } else {
        [self deleteCellsAtIndexPaths:
         [self.class indexPathArrayWithRange:NSMakeRange(targetRowCount, currentRowCount - targetRowCount)
                                   inSection:index]];
    }
}

#pragma mark - SSBaseDataSource

- (NSUInteger)numberOfItemsInSection:(NSInteger)section {
    NSUInteger itemCount = [super numberOfItemsInSection:section];
    
    return ([self isSectionExpandedAtIndex:section]
            ? itemCount
            : MIN(itemCount, [self numberOfCollapsedRowsInSection:section]));
}

#pragma mark - Adding Items

- (void)insertItem:(id)item atIndexPath:(NSIndexPath *)indexPath {
    [self insertItems:@[ item ]
            atIndexes:[NSIndexSet indexSetWithIndex:indexPath.row]
            inSection:indexPath.section];
}

- (void)appendItems:(NSArray *)items toSection:(NSInteger)section {
    NSUInteger itemCount = [self sectionAtIndex:section].numberOfItems;
    
    [self insertItems:items
            atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(itemCount, [items count])]
            inSection:section];
}

- (void)insertItems:(NSArray *)items
          atIndexes:(NSIndexSet *)indexes
          inSection:(NSInteger)section {
    
    [[self sectionAtIndex:section].items insertObjects:items
                                             atIndexes:indexes];
    
    NSArray *potentialIndexes = [self.class indexPathArrayWithIndexSet:indexes
                                                             inSection:section];
    
    [self performBatchUpdates:^{
        [potentialIndexes enumerateObjectsUsingBlock:^(NSIndexPath *indexpath,
                                                       NSUInteger index,
                                                       BOOL *stop) {
            if ([self isItemVisibleAtIndexPath:indexpath]) {
                [self insertCellsAtIndexPaths:@[ indexpath ]];
            }
        }];
    }];
}

#pragma mark - Replacing

- (void)replaceItemAtIndexPath:(NSIndexPath *)indexPath withItem:(id)item {
    
    [[self sectionAtIndex:indexPath.section].items removeObjectAtIndex:(NSUInteger)indexPath.row];
    [[self sectionAtIndex:indexPath.section].items insertObject:item
                                                        atIndex:(NSUInteger)indexPath.row];
    
    if ([self isItemVisibleAtIndexPath:indexPath]) {
        [self reloadCellsAtIndexPaths:@[ indexPath ]];
    }
}

#pragma mark - Removing

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath {
    [self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)indexPath.row]
                     inSection:indexPath.section];
}

- (void)removeItemsInRange:(NSRange)range inSection:(NSInteger)section {
    [self removeItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]
                     inSection:section];
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes inSection:(NSInteger)section {
    [[self sectionAtIndex:section].items removeObjectsAtIndexes:indexes];
    
    if (self.shouldRemoveEmptySections && [self sectionAtIndex:section].numberOfItems == 0) {
        [self removeSectionAtIndex:section];
    } else {
        NSArray *potentialIndexes = [self.class indexPathArrayWithIndexSet:indexes
                                                                 inSection:section];
        
        [self performBatchUpdates:^{
            [potentialIndexes enumerateObjectsUsingBlock:^(NSIndexPath *indexpath,
                                                           NSUInteger index,
                                                           BOOL *stop) {
                if ([self isItemVisibleAtIndexPath:indexpath]) {
                    [self deleteCellsAtIndexPaths:@[ indexpath ]];
                }
            }];
        }];
    }
}

#pragma mark - Internal

- (void)performBatchUpdates:(void (^)(void))updates {
    if (self.collectionView) {
        [self.collectionView performBatchUpdates:updates completion:nil];
    }
    
    if (self.tableView) {
        [self.tableView beginUpdates];
        updates();
        [self.tableView endUpdates];
    }
}

@end
