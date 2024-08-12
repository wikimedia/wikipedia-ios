#import "WMFSourceEditorFormatterBase.h"
#import "WMFSourceEditorColors.h"
#import "WMFSourceEditorFonts.h"

@interface WMFSourceEditorFormatterBase ()

@property (strong, nonatomic) NSDictionary *attributes;

@end

@implementation WMFSourceEditorFormatterBase

- (instancetype)initWithColors:(nonnull WMFSourceEditorColors *)colors fonts:(nonnull WMFSourceEditorFonts *)fonts textAlignment: (NSTextAlignment)textAlignment {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:5];
        [paragraphStyle setLineHeightMultiple:1.1];
        [paragraphStyle setAlignment:textAlignment];

        _attributes = @{
            NSFontAttributeName: fonts.baseFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: colors.baseForegroundColor
        };
    }
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
        return;
    }
    
    // reset base attributes
    [attributedString removeAttribute:NSFontAttributeName range:range];
    [attributedString removeAttribute:NSForegroundColorAttributeName range:range];
    [attributedString removeAttribute:NSBackgroundColorAttributeName range:range];
    
    // reset shared custom attributes
    [attributedString removeAttribute:WMFSourceEditorCustomKeyColorOrange range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyColorGreen range:range];
    [attributedString removeAttribute:WMFSourceEditorCustomKeyColorOrange range:range];
    
    [attributedString addAttributes:self.attributes range:range];
}

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
        return;
    }
    
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.attributes];
    [mutAttributes setObject:colors.baseForegroundColor forKey:NSForegroundColorAttributeName];
    self.attributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];

    [attributedString addAttributes:self.attributes range:range];
}

- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
        return;
    }
    
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.attributes];
    [mutAttributes setObject:fonts.baseFont forKey:NSFontAttributeName];
    self.attributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];

    [attributedString addAttributes:self.attributes range:range];
}

@end
