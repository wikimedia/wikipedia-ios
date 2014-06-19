//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars_iOS.h"

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
    // Temp hack for supplemental iOS wikifont.
    BOOL isIOSFontChar = NO;

    if (
        [text isEqualToString:IOS_WIKIGLYPH_W] ||
        [text isEqualToString:IOS_WIKIGLYPH_TOC] ||
        [text isEqualToString:IOS_WIKIGLYPH_SHARE] ||
        [text isEqualToString:IOS_WIKIGLYPH_MAGNIFY] ||
        [text isEqualToString:IOS_WIKIGLYPH_FORWARD] ||
        [text isEqualToString:IOS_WIKIGLYPH_BACKWARD]
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
