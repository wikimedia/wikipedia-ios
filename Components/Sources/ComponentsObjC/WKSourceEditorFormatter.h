#import <Foundation/Foundation.h>
@class WKSourceEditorColors, WKSourceEditorFonts;

NS_ASSUME_NONNULL_BEGIN

@interface WKSourceEditorFormatter : NSObject

extern NSString *const WKSourceEditorCustomKeyColorOrange;
extern NSString *const WKSourceEditorCustomKeyColorGreen;

- (instancetype)initWithColors:(nonnull WKSourceEditorColors *)colors fonts:(nonnull WKSourceEditorFonts *)fonts;
- (void)addSyntaxHighlightingToAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range;

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range;
- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range;

- (BOOL)canEvaluateAttributedString: (NSAttributedString *)attributedString againstRange: (NSRange)range;
@end

NS_ASSUME_NONNULL_END
