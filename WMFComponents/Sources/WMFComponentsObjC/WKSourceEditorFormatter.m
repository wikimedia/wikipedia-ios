#import "WKSourceEditorFormatter.h"
#import "WKSourceEditorColors.h"
#import "WKSourceEditorFonts.h"

@implementation WKSourceEditorFormatter

#pragma mark - Common Custom Attributed String Keys

// Font and Color custom attributes allow us to easily target already-formatted ranges. This is handy for speedy updates upon theme and text size change, as well as determining keyboard button selection states.
NSString * const WKSourceEditorCustomKeyColorOrange = @"WKSourceEditorKeyColorOrange";
NSString * const WKSourceEditorCustomKeyColorGreen = @"WKSourceEditorKeyColorGreen";

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

- (BOOL)canEvaluateAttributedString: (NSAttributedString *)attributedString againstRange: (NSRange)range {
    
    if (range.location == NSNotFound) {
        return NO;
    }
    
    if (attributedString.length == 0) {
        return NO;
    }
    
    if (attributedString.length <= range.location) {
        return NO;
    }
    
    if (attributedString.length < (range.location + range.length)) {
        return NO;
    }
    
    return YES;
}

@end
