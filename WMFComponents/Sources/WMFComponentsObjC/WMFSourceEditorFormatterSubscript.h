#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterSubscript: WMFSourceEditorFormatter

- (BOOL) attributedString:(NSMutableAttributedString *)attributedString isSubscriptInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
