#import "WKSourceEditorFormatterBase.h"
#import "WKSourceEditorColors.h"
#import "WKSourceEditorFonts.h"

@interface WKSourceEditorFormatterBase ()

@property (strong, nonatomic) NSDictionary *attributes;

@end

@implementation WKSourceEditorFormatterBase

- (instancetype)initWithColors:(nonnull WKSourceEditorColors *)colors fonts:(nonnull WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:5];
        [paragraphStyle setLineHeightMultiple:1.1];

        _attributes = @{
            NSFontAttributeName: fonts.defaultFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: colors.defaultForegroundColor
        };
    }
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    [attributedString addAttributes:self.attributes range:range];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.attributes];
    [mutAttributes setObject:colors.defaultForegroundColor forKey:NSForegroundColorAttributeName];
    self.attributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];

    [attributedString addAttributes:self.attributes range:range];
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.attributes];
    [mutAttributes setObject:fonts.defaultFont forKey:NSFontAttributeName];
    self.attributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];

    [attributedString addAttributes:self.attributes range:range];
}

@end
