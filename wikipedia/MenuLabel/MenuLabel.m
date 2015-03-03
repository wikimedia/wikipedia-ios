//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MenuLabel.h"
#import "WikiGlyph_Chars.h"
#import "Defines.h"
#import "UIFont+WMFStyle.h"

@interface MenuLabel ()

@property (strong, nonatomic) NSString* text;

@property (strong, nonatomic) MenuLabel* label;

@property (nonatomic) CGFloat fontSize;

@property (nonatomic) BOOL fontBold;

@property (nonatomic) UIEdgeInsets padding;

@end

@implementation MenuLabel

- (instancetype)init {
    return [self initWithText:@"" fontSize:16.0 * MENUS_SCALE_MULTIPLIER bold:NO color:[UIColor blackColor] padding:UIEdgeInsetsZero];
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    return [self initWithText:@"" fontSize:16.0 * MENUS_SCALE_MULTIPLIER bold:NO color:[UIColor blackColor] padding:UIEdgeInsetsZero];
}

- (instancetype)initWithText:(NSString*)text
                    fontSize:(CGFloat)size
                        bold:(BOOL)bold
                       color:(UIColor*)color
                     padding:(UIEdgeInsets)padding {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.padding                                   = padding;
        self.fontBold                                  = bold;
        self.color                                     = color;
        self.fontSize                                  = size * MENUS_SCALE_MULTIPLIER;
        self.textAlignment                             = NSTextAlignmentCenter;
        self.adjustsFontSizeToFitWidth                 = YES;
        self.text                                      = text;
        self.backgroundColor                           = [UIColor clearColor];

        self.layer.borderWidth   = 2.0 / [UIScreen mainScreen].scale;
        self.layer.cornerRadius  = 2.0;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)setColor:(UIColor*)color {
    _color = color;
    // Force the text to use new color.
    if (self.text) {
        self.text = self.text;
    }
}

- (void)setText:(NSString*)text {
    UIFont* font = (self.fontBold) ? [UIFont boldSystemFontOfSize : self.fontSize] :[UIFont systemFontOfSize:self.fontSize];

    NSMutableDictionary* attributes =
        @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: self.color
    }.mutableCopy;

    // Quick hack to allow WikiGlyph check character buttons.
    // (Would be nice to have a "isWikiGlyph" function which would determine if a
    // single character string was a WikiGlyph rather than using isEqualToString.)
    if ([text isEqualToString:WIKIGLYPH_TICK]) {
        self.adjustsFontSizeToFitWidth  = NO;
        attributes[NSFontAttributeName] = [UIFont wmf_glyphFontOfSize:self.fontSize];
        NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment                  = NSTextAlignmentCenter;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    }

    self.attributedText =
        [[NSAttributedString alloc] initWithString:text
                                        attributes:attributes];
}

@end
