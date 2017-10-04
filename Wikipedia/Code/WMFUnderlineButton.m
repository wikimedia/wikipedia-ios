#import "WMFUnderlineButton.h"
#import "UIFont+WMFStyle.h"

@interface WMFUnderlineButton ()

@property (nonatomic, strong) UIView *underline;

@end

@implementation WMFUnderlineButton

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self configureStyle];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self configureStyle];
    }
    return self;
}

- (void)configureStyle {
    self.titleLabel.font = [UIFont wmf_subtitle];
    [self addUnderline];
    [self setTitleColor:self.tintColor forState:UIControlStateSelected];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.underline.backgroundColor = self.tintColor;
    [self setTitleColor:self.tintColor forState:UIControlStateSelected];
}

- (void)addUnderline {
    self.underlineHeight = 1.0;
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = self.tintColor;
    v.frame = CGRectMake(0, self.bounds.size.height - self.underlineHeight, self.bounds.size.width, self.underlineHeight);
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

@end
