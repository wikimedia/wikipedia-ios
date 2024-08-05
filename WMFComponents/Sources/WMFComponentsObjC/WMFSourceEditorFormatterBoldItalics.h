#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterBoldItalics : WMFSourceEditorFormatter

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isBoldInRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isItalicsInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
