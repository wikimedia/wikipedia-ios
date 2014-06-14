//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MenuLabel.h"

@interface MenuLabel ()

@property (strong, nonatomic) NSString *text;

@property (strong, nonatomic) MenuLabel *label;

@property (nonatomic) CGFloat fontSize;

@property (nonatomic) UIEdgeInsets padding;

@end

@implementation MenuLabel

- (instancetype)init
{
    return [self initWithText:@"" fontSize:16 color:[UIColor blackColor] padding:UIEdgeInsetsZero];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [self initWithText:@"" fontSize:16 color:[UIColor blackColor] padding:UIEdgeInsetsZero];
}

- (instancetype)initWithText: (NSString *)text
                    fontSize: (CGFloat)size
                       color: (UIColor *)color
                     padding: (UIEdgeInsets)padding
{
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.padding = padding;
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

-(void)setColor:(UIColor *)color
{
    _color = color;
    // Force the text to use new color.
    if (self.text) self.text = self.text;
}

-(void)setText:(NSString *)text
{
    NSDictionary *attributes =
    @{
      NSFontAttributeName: [UIFont systemFontOfSize:self.fontSize],
      NSForegroundColorAttributeName : self.color
      };
    
    self.attributedText =
        [[NSAttributedString alloc] initWithString: text
                                        attributes: attributes];
}

@end
