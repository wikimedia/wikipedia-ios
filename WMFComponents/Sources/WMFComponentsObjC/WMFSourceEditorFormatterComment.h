#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterComment : WMFSourceEditorFormatter
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isCommentInRange:(NSRange)range;
@end

NS_ASSUME_NONNULL_END
