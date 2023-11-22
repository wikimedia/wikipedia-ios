#import "WKSourceEditorFormatter.h"
#import "WKSourceEditorColors.h"
#import "WKSourceEditorFonts.h"

@implementation WKSourceEditorFormatter
- (nonnull instancetype)initWithColors:(nonnull WKSourceEditorColors *)colors fonts:(nonnull WKSourceEditorFonts *)fonts {
    self = [super init];
    return self;
}
- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    NSAssert(false, @"Formatters must override this method.");
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    NSAssert(false, @"Formatters must override this method.");
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    NSAssert(false, @"Formatters must override this method.");
}

@end
