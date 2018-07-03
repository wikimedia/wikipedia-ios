#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars.h"

@interface WikiGlyphLabel ()

@property (nonatomic, strong) UIColor *color;
@property (nonatomic) CGFloat size;
@property (nonatomic) CGFloat baselineOffset;

@end

@implementation WikiGlyphLabel

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

- (void)setup {
    self.textAlignment = NSTextAlignmentCenter;
    self.adjustsFontSizeToFitWidth = YES;
    self.backgroundColor = [UIColor clearColor];
}

- (void)setWikiText:(NSString *)text color:(UIColor *)color size:(CGFloat)size baselineOffset:(CGFloat)baselineOffset {
    self.color = color;
    self.size = size;
    self.baselineOffset = baselineOffset;

    NSDictionary *attributes =
        @{
            NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Glyphs" size:size],
            NSForegroundColorAttributeName: color,
            NSBaselineOffsetAttributeName: @(baselineOffset)
        };

    self.attributedText =
        [[NSAttributedString alloc] initWithString:text
                                        attributes:attributes];
}

@end
