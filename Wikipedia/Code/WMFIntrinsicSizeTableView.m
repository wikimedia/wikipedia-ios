#import "WMFIntrinsicSizeTableView.h"

@implementation WMFIntrinsicSizeTableView

- (void)setContentSize:(CGSize)contentSize {
  BOOL didChange = CGSizeEqualToSize(self.contentSize, contentSize);
  [super setContentSize:contentSize];
  if (didChange) {
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
  }
}

- (void)layoutSubviews {
  CGSize oldSize = self.contentSize;
  [super layoutSubviews];
  if (!CGSizeEqualToSize(oldSize, self.contentSize)) {
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
  }
}

- (CGSize)intrinsicContentSize {
  return self.contentSize;
}

- (void)endUpdates {
  [super endUpdates];
  [self invalidateIntrinsicContentSize];
}

- (void)reloadData {
  [super reloadData];
  [self invalidateIntrinsicContentSize];
}

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths
              withRowAnimation:(UITableViewRowAnimation)animation {
  [super reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
  [self invalidateIntrinsicContentSize];
}

- (void)reloadSections:(NSIndexSet *)sections
      withRowAnimation:(UITableViewRowAnimation)animation {
  [super reloadSections:sections withRowAnimation:animation];
  [self invalidateIntrinsicContentSize];
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths
              withRowAnimation:(UITableViewRowAnimation)animation {
  [super insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
  [self invalidateIntrinsicContentSize];
}

- (void)insertSections:(NSIndexSet *)sections
      withRowAnimation:(UITableViewRowAnimation)animation {
  [super insertSections:sections withRowAnimation:animation];
  [self invalidateIntrinsicContentSize];
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths
              withRowAnimation:(UITableViewRowAnimation)animation {
  [super deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
  [self invalidateIntrinsicContentSize];
}

- (void)deleteSections:(NSIndexSet *)sections
      withRowAnimation:(UITableViewRowAnimation)animation {
  [super deleteSections:sections withRowAnimation:animation];
  [self invalidateIntrinsicContentSize];
}

@end
