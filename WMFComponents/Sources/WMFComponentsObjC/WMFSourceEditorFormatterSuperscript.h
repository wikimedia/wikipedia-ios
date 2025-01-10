#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterSuperscript : WMFSourceEditorFormatter

- (BOOL) attributedString:(NSMutableAttributedString *)attributedString isSuperscriptInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END

