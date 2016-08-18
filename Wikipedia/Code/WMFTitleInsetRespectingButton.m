#import "WMFTitleInsetRespectingButton.h"

@implementation WMFTitleInsetRespectingButton

/**
 *  UIButton does not take into account its insets when calculating intrinisic content size
 *  http://stackoverflow.com/a/17806333/48311
 *
 */
- (CGSize)sizeByAddingInsetsToSize:(CGSize)size {
    return CGSizeMake(size.width + self.titleEdgeInsets.left + self.titleEdgeInsets.right,
                      size.height + self.titleEdgeInsets.top + self.titleEdgeInsets.bottom);
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
