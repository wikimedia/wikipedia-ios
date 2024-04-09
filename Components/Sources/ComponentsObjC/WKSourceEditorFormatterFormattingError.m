#import "WKSourceEditorFormatterFormattingError.h"
#import "WKSourceEditorColors.h"

@interface WKSourceEditorFormatterFormattingError ()

@property (nonatomic, strong) NSDictionary *formattingErrorAttributes;
@property (nonatomic, strong) NSDictionary *formattingErrorContentAttributes;
@property (nonatomic, assign) NSRange formattingErrorRange;

@end

@implementation WKSourceEditorFormatterFormattingError

- (BOOL)attributedString:(nonnull NSMutableAttributedString *)attributedString isFormattingErrorInRange:(NSRange)range {
    
}

@end
