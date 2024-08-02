#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterSubscript: WKSourceEditorFormatter

- (BOOL) attributedString:(NSMutableAttributedString *)attributedString isSubscriptInRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
