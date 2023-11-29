#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterBoldItalics : WKSourceEditorFormatter

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isBoldInRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isItalicsInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
