#import "WKSourceEditorFormatter.h"
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatterBase : WKSourceEditorFormatter
- (instancetype)initWithColors:(nonnull WKSourceEditorColors *)colors fonts:(nonnull WKSourceEditorFonts *)fonts textAlignment: (NSTextAlignment)textAlignment;
@end

NS_ASSUME_NONNULL_END
