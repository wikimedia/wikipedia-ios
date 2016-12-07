#import "RecentSearchCell.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"
#import "Wikipedia-Swift.h"

@implementation RecentSearchCell

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self wmf_makeCellDividerBeEdgeToEdge];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self wmf_configureSubviewsForDynamicType];
}

@end
