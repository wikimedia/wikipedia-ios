
#import "SSSectionedDataSource+WMFSectionConvenience.h"

@implementation SSSectionedDataSource (WMFSectionConvenience)

- (NSIndexSet*)indexesOfItemsInSection:(NSInteger)section {
    NSUInteger numberOfItems = [self numberOfItemsInSection:section];
    if (numberOfItems == 0) {
        return nil;
    }

    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfItems)];
}

- (NSArray*)indexPathsOfItemsInSection:(NSInteger)section {
    return [[self indexesOfItemsInSection:section] bk_mapIndex:^id (NSUInteger index) {
        return [NSIndexPath indexPathForItem:index inSection:section];
    }];
}

- (void)setItems:(NSArray*)items inSection:(NSInteger)section {
    [self removeAllItemsInSection:section];
    [self appendItems:items toSection:section];
}

- (void)removeAllItemsInSection:(NSInteger)section {
    NSIndexSet* allItems = [self indexesOfItemsInSection:section];
    if (allItems) {
        [self removeItemsAtIndexes:allItems inSection:section];
    }
}

- (void)reloadCellsAtIndexes:(NSIndexSet*)indexes inSection:(NSInteger)section {
    [self reloadCellsAtIndexPaths:[self indexPathsOfItemsInSection:section]];
}

- (void)reloadSection:(NSInteger)section {
    [self reloadSectionsAtIndexes:[NSIndexSet indexSetWithIndex:section]];
}

- (UICollectionViewCell*)cellForItemAtIndex:(NSInteger)index inSection:(NSInteger)section {
    return [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:section]];
}

@end
