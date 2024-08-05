#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterLink : WMFSourceEditorFormatter
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSimpleLinkInRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isLinkWithNestedLinkInRange:(NSRange)range;
@end

NS_ASSUME_NONNULL_END
