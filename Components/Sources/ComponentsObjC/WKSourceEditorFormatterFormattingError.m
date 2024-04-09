#import "WKSourceEditorFormatterFormattingError.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterFormattingError ()

@property (nonatomic, strong) NSDictionary *formattingErrorAttributes;
@property (nonatomic, strong) NSDictionary *formattingErrorContentAttributes;

@end

@implementation WKSourceEditorFormatterFormattingError

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    if (![self canEvaluateAttributedString:attributedString againstRange:range]) {
       return;
    }
    
    if (![self canEvaluateAttributedString:attributedString againstRange:self.errorRange]) {
       return;
    }
    
    NSDictionary *attributes = @{
        NSBackgroundColorAttributeName: [UIColor redColor],
    };
    
    
    //[attributedString addAttributes:attributes range:self.errorRange];
    
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
}

@end
