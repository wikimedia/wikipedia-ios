#import "MenuLabel.h"

@interface MenuLabel ()

@property (strong, nonatomic) MenuLabel *label;

@property (nonatomic) CGFloat fontSize;

@property (nonatomic) BOOL fontBold;

@end

@implementation MenuLabel

- (instancetype)init {
    return [self initWithText:@"" fontSize:16.0 bold:NO color:[UIColor blackColor] padding:UIEdgeInsetsZero];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithText:@"" fontSize:16.0 bold:NO color:[UIColor blackColor] padding:UIEdgeInsetsZero];
}

- (instancetype)initWithText:(NSString *)text
                    fontSize:(CGFloat)size
                        bold:(BOOL)bold
                       color:(UIColor *)color
                     padding:(UIEdgeInsets)padding {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.padding = padding;
        self.fontBold = bold;
        self.color = color;
        self.fontSize = size;
        self.textAlignment = NSTextAlignmentCenter;
        self.adjustsFontSizeToFitWidth = YES;
        self.text = text;
        self.backgroundColor = [UIColor clearColor];

        self.layer.borderWidth = 2.0 / [UIScreen mainScreen].scale;
        self.layer.cornerRadius = 2.0;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    // Force the text to use new color.
    if (self.text) {
        self.text = self.text;
    }
}

- (void)setText:(NSString *)text {
    UIFont *font = (self.fontBold) ? [UIFont boldSystemFontOfSize:self.fontSize] : [UIFont systemFontOfSize:self.fontSize];

    self.attributedText =
        [[NSAttributedString alloc] initWithString:text
                                        attributes:@{
                                            NSFontAttributeName: font,
                                            NSForegroundColorAttributeName: self.color
                                        }];
}

@end
