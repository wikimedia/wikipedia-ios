#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterSuperscript : WKSourceEditorFormatter

- (BOOL) attributedString:(NSMutableAttributedString *)attributedString isSuperscriptInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END

