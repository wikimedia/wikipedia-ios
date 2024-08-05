#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterUnderline : WMFSourceEditorFormatter

- (BOOL) attributedString:(NSMutableAttributedString *)attributedString isUnderlineInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
