
#import "WMFIntrinsicSizeCollectionView.h"

@implementation WMFIntrinsicSizeCollectionView

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

@end
