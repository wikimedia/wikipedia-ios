#import <Foundation/Foundation.h>
@class WMFSourceEditorColors, WMFSourceEditorFonts;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSourceEditorFormatter : NSObject

extern NSString *const WMFSourceEditorCustomKeyColorOrange;
extern NSString *const WMFSourceEditorCustomKeyColorGreen;

- (instancetype)initWithColors:(nonnull WMFSourceEditorColors *)colors fonts:(nonnull WMFSourceEditorFonts *)fonts;
- (void)addSyntaxHighlightingToAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range;

- (void)updateColors:(WMFSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range;
- (void)updateFonts:(WMFSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range;

- (BOOL)canEvaluateAttributedString: (NSAttributedString *)attributedString againstRange: (NSRange)range;
@end

NS_ASSUME_NONNULL_END
