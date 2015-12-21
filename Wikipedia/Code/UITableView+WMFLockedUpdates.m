//
//  UITableView+WMFLockedUpdates.m
//
//
//  Created by Brian Gerstle on 12/18/15.
//
//

#import "UITableView+WMFLockedUpdates.h"

@implementation UITableView (WMFLockedUpdates)

- (void)      wmf_performUpdates:(dispatch_block_t)updates
    withoutMovingCellAtIndexPath:(NSIndexPath*)lockedIndexPath {
    NSParameterAssert(lockedIndexPath);
    NSParameterAssert(updates);
    if (self.contentSize.height <= self.frame.size.height) {
        DDLogVerbose(@"Content size not large enough to need adjusting, skipping.");
        updates();
        return;
    }

    UITableViewCell* oldLockedCell = [self cellForRowAtIndexPath:lockedIndexPath];
    if (!oldLockedCell) {
        DDLogVerbose(@"Cell at %@ not visible, skipping.", lockedIndexPath);
        updates();
        return;
    }

    CGPoint oldOrigin = [self.window convertPoint:oldLockedCell.frame.origin
                                         fromView:oldLockedCell.superview];
    [UIView performWithoutAnimation:^{
        updates();

        if (self.contentSize.height <= self.frame.size.height) {
            DDLogVerbose(@"Content size too small after updates, not adjusting content offset.");
            return;
        }

        UITableViewCell* newLockedCell = [self cellForRowAtIndexPath:lockedIndexPath];
        if (!newLockedCell) {
            DDLogVerbose(@"Can't find cell to lock for %@ after updates, skipping adjustment.", lockedIndexPath);
            return;
        }

        CGPoint currentOrigin = [self.window convertPoint:newLockedCell.frame.origin
                                                 fromView:newLockedCell.superview];
        CGPoint newContentOffset = self.contentOffset;

        newContentOffset.y += currentOrigin.y - oldOrigin.y;
        // ???: if deleting from above selected/focused row, do we need to limit auto-scrolling to contentInset?

        DDLogVerbose(@"Adjusting content offset to %@ to prevent updates from moving cell at %@.",
                     NSStringFromCGPoint(newContentOffset),
                     lockedIndexPath);
        self.contentOffset = newContentOffset;
    }];
}

@end
