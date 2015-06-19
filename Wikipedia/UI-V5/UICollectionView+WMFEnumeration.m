
#import "UICollectionView+WMFEnumeration.h"

@implementation UICollectionView (WMFEnumeration)

- (void)wmf_enumerateIndexPathsUsingBlock:(void (^)(NSIndexPath* indexPath, BOOL* stop))block {
    BOOL stop = NO;

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

- (void)wmf_enumerateVisibleIndexPathsUsingBlock:(void (^)(NSIndexPath* indexPath, BOOL* stop))block {
    [self.indexPathsForVisibleItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        if (block) {
            block(obj, stop);
        }
    }];
}

@end
