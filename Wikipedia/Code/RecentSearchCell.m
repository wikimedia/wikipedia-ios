#import "RecentSearchCell.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@implementation RecentSearchCell

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self wmf_makeCellDividerBeEdgeToEdge];
  }
  return self;
}

@end
