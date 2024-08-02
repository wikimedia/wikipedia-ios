#import "WMFSourceEditorFormatter.h"
#import "WMFSourceEditorColors.h"
#import "WMFSourceEditorFonts.h"

@implementation WMFSourceEditorFormatter

#pragma mark - Common Custom Attributed String Keys

// Font and Color custom attributes allow us to easily target already-formatted ranges. This is handy for speedy updates upon theme and text size change, as well as determining keyboard button selection states.
NSString * const WMFSourceEditorCustomKeyColorOrange = @"WMFSourceEditorKeyColorOrange";
NSString * const WMFSourceEditorCustomKeyColorGreen = @"WMFSourceEditorKeyColorGreen";

- (nonnull instancetype)initWithColors:(nonnull WMFSourceEditorColors *)colors fonts:(nonnull WMFSourceEditorFonts *)fonts {
    self = [super init];
    return self;
}
- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    NSAssert(false, @"Formatters must override this method.");
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    NSAssert(false, @"Formatters must override this method.");
}

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
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
