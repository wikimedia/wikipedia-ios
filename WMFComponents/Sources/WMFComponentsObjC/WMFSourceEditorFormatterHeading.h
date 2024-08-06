#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterHeading : WMFSourceEditorFormatter

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isHeadingInRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading1InRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading2InRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading3InRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isSubheading4InRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
