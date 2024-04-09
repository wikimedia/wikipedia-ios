#import "WKSourceEditorFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterFormattingError: WKSourceEditorFormatter

@property (nonatomic, assign) NSRange errorRange;

@end

NS_ASSUME_NONNULL_END
