
#import "UICollectionView+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UICollectionView (WMFExtensions)

- (NSArray*)wmf_indexPathsForIndexes:(NSIndexSet* __nonnull)indexes inSection:(NSInteger)section {
    return [indexes bk_mapIndex:^id (NSUInteger index) {
        return [NSIndexPath indexPathForRow:(NSInteger)index inSection:section];
    }];
}

- (void)wmf_enumerateIndexPathsUsingBlock:(WMFIndexPathEnumerator)block {
    BOOL stop              = NO;
    NSInteger sectionCount = [self numberOfSections];
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger rowCount = [self numberOfItemsInSection:section];
        for (NSInteger row = 0; row < rowCount; row++) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForItem:row inSection:section];
            if (block) {
                block(indexPath, &stop);
            }
            if (stop) {
                return;
            }
        }
    }
}

- (void)wmf_enumerateVisibleIndexPathsUsingBlock:(WMFIndexPathEnumerator)block {
    [self.indexPathsForVisibleItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        if (block) {
            block(obj, stop);
        }
    }];
}

- (void)wmf_enumerateVisibleCellsUsingBlock:(WMFCellEnumerator)block {
    [self wmf_enumerateVisibleIndexPathsUsingBlock:^(NSIndexPath* path, BOOL* stop) {
        id cell = [self cellForItemAtIndexPath:path];
        if (cell) {
            block(cell, path, stop);
        }
    }];
}

- (NSIndexPath*)wmf_indexPathBeforeIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.item == 0) {
        if (indexPath.section == 0) {
            return nil;
        }
        NSInteger previousSection = indexPath.section - 1;
        NSInteger previousItem    = [self numberOfItemsInSection:previousSection] - 1;
        return [NSIndexPath indexPathForItem:previousItem inSection:previousSection];
    }

    NSInteger previousItem = indexPath.item - 1;
    return [NSIndexPath indexPathForItem:previousItem inSection:indexPath.section];
}

- (NSIndexPath*)wmf_indexPathAfterIndexPath:(NSIndexPath*)indexPath {
    NSInteger nextItem = indexPath.item + 1;
    if (nextItem < [self numberOfItemsInSection:indexPath.section]) {
        return [NSIndexPath indexPathForItem:nextItem inSection:indexPath.section];
    }

    NSInteger nextSection = indexPath.section + 1;

    if (nextSection < [self numberOfSections]) {
        return [NSIndexPath indexPathForItem:0 inSection:nextSection];
    }

    return nil;
}

/**
 *  Like other UIKit methods, the completion isn't called if you pass animated = false.
 *  This method ensures the completion block is always called.
 */
- (void)wmf_setCollectionViewLayout:(UICollectionViewLayout*)layout animated:(BOOL)animated alwaysFireCompletion:(void (^)(BOOL finished))completion {
    [self setCollectionViewLayout:layout animated:animated completion:^(BOOL finished) {
        if (animated && completion) {
            completion(finished);
        }
    }];

    if (!animated && completion) {
        completion(YES);
    }
}

- (NSArray*)wmf_visibleIndexPathsOfItemsBeforeIndexPath:(NSIndexPath*)indexPath {
    return [[self indexPathsForVisibleItems] bk_select:^BOOL (NSIndexPath* obj) {
        if (obj.section > indexPath.section) {
            return NO;
        }

        if (obj.row < indexPath.row) {
            return YES;
        }

        return NO;
    }];
}

- (NSArray*)wmf_visibleIndexPathsOfItemsAfterIndexPath:(NSIndexPath*)indexPath {
    return [[self indexPathsForVisibleItems] bk_select:^BOOL (NSIndexPath* obj) {
        if (obj.section < indexPath.section) {
            return NO;
        }

        if (obj.row > indexPath.row) {
            return YES;
        }

        return NO;
    }];
}

- (CGRect)wmf_rectEnclosingCellsAtIndexPaths:(NSArray*)indexPaths {
    __block CGRect enclosingRect = CGRectZero;

    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL* stop) {
        UICollectionViewCell* cell = [self cellForItemAtIndexPath:obj];

        if (!cell) {
            return;
        }

        if (CGRectIsEmpty(enclosingRect)) {
            enclosingRect = cell.frame;
        } else {
            enclosingRect = CGRectUnion(enclosingRect, cell.frame);
        }
    }];

    return enclosingRect;
}

- (UIView*)wmf_snapshotOfVisibleCells {
    NSArray* indexpaths = [self indexPathsForVisibleItems];
    return [self wmf_snapshotOfCellsAtIndexPaths:indexpaths];
}

- (UIView*)wmf_snapshotOfCellAtIndexPath:(NSIndexPath*)indexPath {
    return [self wmf_snapshotOfCellsAtIndexPaths:@[indexPath]];
}

- (UIView*)wmf_snapshotOfCellsAtIndexPaths:(NSArray*)indexPaths {
    __block CGRect snapShotRect = [self wmf_rectEnclosingCellsAtIndexPaths:indexPaths];

    if (CGRectIsEmpty(snapShotRect)) {
        return nil;
    } else {
        return [self resizableSnapshotViewFromRect:snapShotRect afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    }
}

- (UIView*)wmf_snapshotOfCellsBeforeIndexPath:(NSIndexPath*)indexPath {
    return [self wmf_snapshotOfCellsAtIndexPaths:[self wmf_visibleIndexPathsOfItemsBeforeIndexPath:indexPath]];
}

- (UIView*)wmf_snapshotOfCellsAfterIndexPath:(NSIndexPath*)indexPath {
    return [self wmf_snapshotOfCellsAtIndexPaths:[self wmf_visibleIndexPathsOfItemsAfterIndexPath:indexPath]];
}

@end

NS_ASSUME_NONNULL_END
