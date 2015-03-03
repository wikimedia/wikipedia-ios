//  Created by Monte Hurd on 2/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFIntrinsicContentSizeAwareTableView.h"

@implementation WMFIntrinsicContentSizeAwareTableView

/*
   These intrinsicContentSize overrides allow us to use the table view in
   non-scrolling presentations (like "Read more") which can grow/shrink
   vertically depending on how many rows are being shown.

   Based on: http://stackoverflow.com/a/17335818
 */

- (CGSize)intrinsicContentSize {
    [self layoutIfNeeded];
    return CGSizeMake(UIViewNoIntrinsicMetric, self.contentSize.height);
}

- (void)reloadData {
    [super reloadData];
    [self invalidateIntrinsicContentSize];
}

- (void)endUpdates {
    [super endUpdates];
    [self invalidateIntrinsicContentSize];
}

- (void)insertRowsAtIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)reloadRowsAtIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)reloadSections:(NSIndexSet*)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [super reloadSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)insertSections:(NSIndexSet*)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [super insertSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)deleteRowsAtIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [super deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

- (void)deleteSections:(NSIndexSet*)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [super deleteSections:sections withRowAnimation:animation];
    [self invalidateIntrinsicContentSize];
}

@end
