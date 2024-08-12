#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterReference : WMFSourceEditorFormatter
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isHorizontalReferenceInRange:(NSRange)range;
@end

NS_ASSUME_NONNULL_END
