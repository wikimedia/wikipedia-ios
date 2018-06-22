#import "WMFUnderlineButton.h"
@import WMF;

IB_DESIGNABLE
@interface WMFUnderlineButton ()

@property (nonatomic, strong) UIView *underline;
@property (nonatomic) IBInspectable CGFloat underlineHeight;
@property (nonatomic) IBInspectable BOOL useDefaultFont;

@end

@implementation WMFUnderlineButton

- (void)awakeFromNib {
    [super awakeFromNib];
    if (self) {
        [self configureStyle];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self configureStyle];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self inspectableDefaults];
    }
    return self;
}

- (void)configureStyle {
    if (self.useDefaultFont) {
        self.titleLabel.font = [UIFont wmf_fontForDynamicTextStyle:[WMFDynamicTextStyle subheadline]];
    }
    [self addUnderline];
    [self setTitleColor:self.tintColor forState:UIControlStateSelected];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.underline.backgroundColor = self.tintColor;
    [self setTitleColor:self.tintColor forState:UIControlStateSelected];
}

- (void)addUnderline {
    CGFloat underlineHeight = self.underlineHeight;
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = self.tintColor;
    CGRect underlineRect = CGRectMake(0, self.bounds.size.height - underlineHeight, self.bounds.size.width, underlineHeight);
    underlineRect = CGRectInset(underlineRect, 2, 0);
    v.frame = underlineRect;
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:v];
    self.underline = v;
    [self setSelected:self.selected];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.underline.alpha = 1.0;
    } else {
        self.underline.alpha = 0.0;
    }
}

- (void)inspectableDefaults {
    _useDefaultFont = YES;
    _underlineHeight = 1.0;
}

@end
