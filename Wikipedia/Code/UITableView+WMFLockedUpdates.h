#import <UIKit/UIKit.h>

@interface UITableView (WMFLockedUpdates)

- (void)wmf_performUpdates:(dispatch_block_t)updates
    withoutMovingCellAtIndexPath:(NSIndexPath *)lockedIndexPath;

@end
