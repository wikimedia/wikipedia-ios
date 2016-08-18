#import "PaddedLabel.h"

@interface WikiGlyphLabel : PaddedLabel

- (void)setWikiText:(NSString *)text color:(UIColor *)color size:(CGFloat)size baselineOffset:(CGFloat)baselineOffset;

@property (nonatomic, strong, readonly) UIColor *color;
@property (nonatomic, readonly) CGFloat size;
@property (nonatomic, readonly) CGFloat baselineOffset;

@end
