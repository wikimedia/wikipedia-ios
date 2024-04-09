#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterFormattingError: WKSourceEditorFormatter

- (BOOL) attributedString:(NSMutableAttributedString *)attributedString isFormattingErrorInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
