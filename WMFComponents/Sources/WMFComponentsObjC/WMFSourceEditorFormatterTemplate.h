#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterTemplate : WMFSourceEditorFormatter

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isHorizontalTemplateInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
