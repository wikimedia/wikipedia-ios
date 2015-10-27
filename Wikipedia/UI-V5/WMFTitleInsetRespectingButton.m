
#import "WMFTitleInsetRespectingButton.h"

@implementation WMFTitleInsetRespectingButton

/**
 *  UIButton does not take into acocunt its insets when calculating intrinisic content size
 *  http://stackoverflow.com/a/17806333/48311
 *
 */
- (CGSize)intrinsicContentSize {
    CGSize s = [super intrinsicContentSize];

    return CGSizeMake(s.width + self.titleEdgeInsets.left + self.titleEdgeInsets.right,
                      s.height + self.titleEdgeInsets.top + self.titleEdgeInsets.bottom);
}

@end
