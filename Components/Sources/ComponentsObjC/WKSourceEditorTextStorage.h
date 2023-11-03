#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WKSourceEditorColors, WKSourceEditorFonts;

@interface WKSourceEditorTextStorage : NSTextStorage

- (instancetype)initWithColors:(nonnull WKSourceEditorColors *)colors fonts:(nonnull WKSourceEditorFonts *)fonts;

- (void)updateColors:(WKSourceEditorColors *)colors andFonts:(WKSourceEditorFonts *)fonts;

@end

NS_ASSUME_NONNULL_END
