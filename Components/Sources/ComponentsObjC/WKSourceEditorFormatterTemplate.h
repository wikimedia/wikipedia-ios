#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterTemplate : WKSourceEditorFormatter

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isTemplateInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
