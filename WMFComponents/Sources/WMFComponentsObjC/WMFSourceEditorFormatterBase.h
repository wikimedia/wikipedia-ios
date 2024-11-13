#import "WMFSourceEditorFormatter.h"
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatterBase : WMFSourceEditorFormatter
- (instancetype)initWithColors:(nonnull WMFSourceEditorColors *)colors fonts:(nonnull WMFSourceEditorFonts *)fonts textAlignment: (NSTextAlignment)textAlignment;
@end

NS_ASSUME_NONNULL_END
