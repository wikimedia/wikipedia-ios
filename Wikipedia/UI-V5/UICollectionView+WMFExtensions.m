
#import "UICollectionView+WMFExtensions.h"

@implementation UICollectionView (WMFExtensions)

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

/**
 *  Like other UIKit methods, the completion isn't called if you pass animated = false.
 *  This method ensures the completion block is always called.
 */
- (void)wmf_setCollectionViewLayout:(UICollectionViewLayout *)layout animated:(BOOL)animated alwaysFireCompletion:(void (^)(BOOL finished))completion{
    
    [self setCollectionViewLayout:layout animated:animated completion:^(BOOL finished) {
        if(animated && completion){
            completion(finished);
        }
    }];
    
    if(!animated && completion){
        completion(YES);
    }
    
}


@end
