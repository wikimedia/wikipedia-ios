#import "PaddedLabel.h"
#import "Wikipedia-Swift.h"

@implementation PaddedLabel

- (void)layoutSubviews {
    [super layoutSubviews];
    // This fixes problem with PaddedLabels used by UITableViewCells not sizing to their text
    // properly as table cells are recycled by the table.
    [self invalidateIntrinsicContentSize];
}

- (void)setup {
    self.padding = UIEdgeInsetsZero;
    if (self.textAlignment == NSTextAlignmentLeft) {
        self.textAlignment = NSTextAlignmentNatural;
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (CGFloat)getPaddedMaxLayoutWidth {
    return self.bounds.size.width - (self.padding.left + self.padding.right);
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];

    // Keep preferredMaxLayoutWidth in sync with new width so label will grow
    // vertically to encompass its text if the label's width constraint changes.
    // (taking padding into account)
    self.preferredMaxLayoutWidth = [self getPaddedMaxLayoutWidth];
}

// Label padding edge insets! From: http://stackoverflow.com/a/21934948

- (void)drawTextInRect:(CGRect)rect {
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.padding)];
}

- (CGSize)intrinsicContentSize {
    // Set preferredMaxLayoutWidth before the call to super so the super call can
    // take into account the padding. Needed because the padding can affect how many
    // lines are being displayed, which can increase the intrinsicContentSize
    // height.
    self.preferredMaxLayoutWidth = [self getPaddedMaxLayoutWidth];

    CGSize contentSize = [super intrinsicContentSize];
    contentSize.height += self.padding.top + self.padding.bottom;
    contentSize.width += self.padding.left + self.padding.right;
    return contentSize;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self invalidateIntrinsicContentSize];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    [self invalidateIntrinsicContentSize];
}

- (void)setPadding:(UIEdgeInsets)padding {
    // Adjust padding for scale.
    padding = UIEdgeInsetsMake(
        ceil((CGFloat)padding.top),
        ceil((CGFloat)padding.left),
        ceil((CGFloat)padding.bottom),
        ceil((CGFloat)padding.right));

    // Adjust for RTL langs.
    if ([[UIApplication sharedApplication] wmf_isRTL]) {
        _padding = UIEdgeInsetsMake(padding.top, padding.right, padding.bottom, padding.left);
    } else {
        _padding = padding;
    }

    [self invalidateIntrinsicContentSize];
}

@end
