#import "WMFShareOptionsView.h"
#import "PaddedLabel.h"
#import "UIView+WMFRoundCorners.h"

static int const kCornerRadius = 4.2f;

@implementation WMFShareOptionsView

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.cardImageViewContainer wmf_roundCorners:UIRectCornerTopLeft | UIRectCornerTopRight toRadius:kCornerRadius];
    [self.shareAsCardLabel wmf_roundCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight toRadius:kCornerRadius];
    self.shareAsTextLabel.layer.cornerRadius = kCornerRadius;
    self.shareAsTextLabel.layer.masksToBounds = YES;
    self.cancelLabel.layer.cornerRadius = kCornerRadius;
    self.cancelLabel.layer.masksToBounds = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

- (BOOL)accessibilityPerformEscape {
    [self.accessibilityDelegate accessibilityPerformEscape];
    return true;
}

@end
