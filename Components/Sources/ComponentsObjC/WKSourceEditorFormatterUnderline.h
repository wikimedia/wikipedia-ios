#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterUnderline : WKSourceEditorFormatter

- (BOOL) attributedString:(NSMutableAttributedString *)attributedString isUnderlineInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
