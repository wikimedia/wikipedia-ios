#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterStrikethrough : WMFSourceEditorFormatter

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isStrikethroughInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
