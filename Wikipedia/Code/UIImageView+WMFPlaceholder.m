#import "UIImageView+WMFPlaceholder.h"
#import "UIImage+WMFStyle.h"
#import "UIColor+WMFStyle.h"
#import "UIImageView+WMFImageFetching.h"
#import <objc/runtime.h>

@implementation UIImageView (WMFPlaceholder)

static const void *WMFPlaceholderKey = &WMFPlaceholderKey;

- (void)wmf_hidePlaceholder {
    UIImageView *placeholderView = objc_getAssociatedObject(self, WMFPlaceholderKey);
    placeholderView.alpha = 0;
}

- (void)wmf_showPlaceholder {
    self.image = nil;
    self.wmf_placeholderView.alpha = 1;
}

- (UIImageView *)wmf_placeholderView {
    UIImageView *placeholderView = objc_getAssociatedObject(self, WMFPlaceholderKey);
    if (!placeholderView) {
        placeholderView = [[UIImageView alloc] initWithImage:[UIImage wmf_placeholderImage]];
        placeholderView.frame = self.bounds;
        placeholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        placeholderView.contentMode = UIViewContentModeCenter;
        placeholderView.backgroundColor = [UIColor wmf_placeholderImageBackgroundColor];
        placeholderView.tintColor = [UIColor wmf_placeholderImageTintColor];
        [self addSubview:placeholderView];
        objc_setAssociatedObject(self, WMFPlaceholderKey, placeholderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return placeholderView;
}

@end
