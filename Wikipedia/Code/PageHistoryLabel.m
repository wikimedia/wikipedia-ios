#import "PageHistoryLabel.h"
#import "Defines.h"

@implementation PageHistoryLabel

- (void)didMoveToSuperview {
    self.font = [UIFont systemFontOfSize:12.0f * MENUS_SCALE_MULTIPLIER];
}

@end
