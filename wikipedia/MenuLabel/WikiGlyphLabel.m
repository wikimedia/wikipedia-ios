//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars_iOS.h"

@interface WikiGlyphLabel()

@property(nonatomic, strong) UIColor *color;
@property(nonatomic) CGFloat size;
@property(nonatomic) CGFloat baselineOffset;

@end

@implementation WikiGlyphLabel

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.textAlignment = NSTextAlignmentCenter;
    self.adjustsFontSizeToFitWidth = YES;
    self.backgroundColor = [UIColor clearColor];
}

-(void)setWikiText:(NSString *)text color:(UIColor *)color size:(CGFloat)size baselineOffset:(CGFloat)baselineOffset
{
    self.color = color;
    self.size = size;
    self.baselineOffset = baselineOffset;

    // Temp hack for supplemental iOS wikifont.
    BOOL isIOSFontChar = NO;

    if (
        [text isEqualToString:IOS_WIKIGLYPH_W] ||
        [text isEqualToString:IOS_WIKIGLYPH_TOC_COLLAPSED] ||
        [text isEqualToString:IOS_WIKIGLYPH_TOC_EXPANDED] ||
        [text isEqualToString:IOS_WIKIGLYPH_SHARE] ||
        [text isEqualToString:IOS_WIKIGLYPH_MAGNIFY] ||
        [text isEqualToString:IOS_WIKIGLYPH_FORWARD] ||
        [text isEqualToString:IOS_WIKIGLYPH_BACKWARD] ||
        [text isEqualToString:IOS_WIKIGLYPH_STAR] ||
        [text isEqualToString:IOS_WIKIGLYPH_STAR_OUTLINE] ||
        [text isEqualToString:IOS_WIKIGLYPH_HEART_OUTLINE] ||
        [text isEqualToString:IOS_WIKIGLYPH_HEART] ||
        [text isEqualToString:IOS_WIKIGLYPH_RELOAD]
        ) {
        isIOSFontChar = YES;
    }
    
    NSString *fontName = isIOSFontChar ? @"WikiFontGlyphs-iOS": @"WikiFont-Glyphs";
    //NSArray *array =[UIFont fontNamesForFamilyName:@"WikiFont-Glyphs"];
    //NSLog(@"array = %@", array);

    NSDictionary *attributes =
    @{
      NSFontAttributeName: [UIFont fontWithName:fontName size:size],
      NSForegroundColorAttributeName : color,
      NSBaselineOffsetAttributeName: @(baselineOffset)
      };
  
    self.attributedText =
        [[NSAttributedString alloc] initWithString: text
                                        attributes: attributes];
}

@end
