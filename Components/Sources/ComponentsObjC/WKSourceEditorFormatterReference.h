#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterReference : WKSourceEditorFormatter
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isHorizontalReferenceInRange:(NSRange)range;
@end

NS_ASSUME_NONNULL_END
