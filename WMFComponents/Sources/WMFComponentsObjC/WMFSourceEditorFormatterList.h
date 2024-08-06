#import "WMFSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterList : WMFSourceEditorFormatter
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isBulletSingleInRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isBulletMultipleInRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isNumberSingleInRange:(NSRange)range;
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isNumberMultipleInRange:(NSRange)range;
@end

NS_ASSUME_NONNULL_END
