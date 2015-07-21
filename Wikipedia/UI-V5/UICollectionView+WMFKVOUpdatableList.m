//
//  UICollectionView+WMFKVOUpdatableList.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UICollectionView+WMFKVOUpdatableList.h"
#import "UICollectionView+WMFExtensions.h"

@implementation UICollectionView (WMFKVOUpdatableList)

- (void)wmf_updateIndexes:(NSIndexSet* __nonnull)indexes
                inSection:(NSInteger)section
            forChangeKind:(NSKeyValueChange)change {
    NSArray* indexPaths = [self wmf_indexPathsForIndexes:indexes inSection:section];
    switch (change) {
        case NSKeyValueChangeInsertion: {
            [self insertItemsAtIndexPaths:indexPaths];
            break;
        }
        case NSKeyValueChangeRemoval: {
            [self deleteItemsAtIndexPaths:indexPaths];
            break;
        }
        case NSKeyValueChangeReplacement: {
            [self reloadItemsAtIndexPaths:indexPaths];
            break;
        }
        case NSKeyValueChangeSetting: {
            [self reloadData];
            break;
        }
    }
}

@end
