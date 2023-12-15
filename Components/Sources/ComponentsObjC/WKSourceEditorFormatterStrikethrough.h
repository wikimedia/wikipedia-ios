#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterStrikethrough : WKSourceEditorFormatter

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isStrikethroughInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
