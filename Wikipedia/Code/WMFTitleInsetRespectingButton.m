#import "WMFTitleInsetRespectingButton.h"

@implementation WMFTitleInsetRespectingButton

/**
 *  UIButton does not take into account its insets when calculating intrinisic content size
 *  http://stackoverflow.com/a/17806333/48311
 *
 */
- (CGSize)sizeByAddingInsetsToSize:(CGSize)size {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return CGSizeMake(size.width + self.titleEdgeInsets.left + self.titleEdgeInsets.right,
                      size.height + self.titleEdgeInsets.top + self.titleEdgeInsets.bottom);
#pragma clang diagnostic pop
}

- (CGSize)intrinsicContentSize {
    CGSize s = [super intrinsicContentSize];
    return [self sizeByAddingInsetsToSize:s];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize s = [super sizeThatFits:size];
    return [self sizeByAddingInsetsToSize:s];
}

@end
