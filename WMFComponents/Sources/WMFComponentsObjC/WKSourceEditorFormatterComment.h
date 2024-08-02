#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterComment : WKSourceEditorFormatter
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isCommentInRange:(NSRange)range;
@end

NS_ASSUME_NONNULL_END
