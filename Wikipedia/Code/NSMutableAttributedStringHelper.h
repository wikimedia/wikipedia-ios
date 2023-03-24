#import <Foundation/Foundation.h>
@import UIKit;
@class WMFTheme;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kCustomAttributedStringKeyWikitextBold;
extern NSString *const kCustomAttributedStringKeyWikitextItalic;
extern NSString *const kCustomAttributedStringKeyWikitextBoldAndItalic;
extern NSString *const kCustomAttributedStringKeyWikitextLink;
extern NSString *const kCustomAttributedStringKeyWikitextImage;
extern NSString *const kCustomAttributedStringKeyWikitextTemplate;
extern NSString *const kCustomAttributedStringKeyWikitextRef;
extern NSString *const kCustomAttributedStringKeyWikitextRefWithAttributes;
extern NSString *const kCustomAttributedStringKeyWikitextRefSelfClosing;
extern NSString *const kCustomAttributedStringKeyWikitextSuperscript;
extern NSString *const kCustomAttributedStringKeyWikitextSubscript;
extern NSString *const kCustomAttributedStringKeyWikitextUnderline;
extern NSString *const kCustomAttributedStringKeyWikitextStrikethrough;
extern NSString *const kCustomAttributedStringKeyWikitextBullet;
extern NSString *const kCustomAttributedStringKeyWikitextNumber;
extern NSString *const kCustomAttributedStringKeyWikitextH2;
extern NSString *const kCustomAttributedStringKeyWikitextH3;
extern NSString *const kCustomAttributedStringKeyWikitextH4;
extern NSString *const kCustomAttributedStringKeyWikitextH5;
extern NSString *const kCustomAttributedStringKeyWikitextH6;
extern NSString *const kCustomAttributedStringKeyWikitextComment;

// Public keys, used only for theming updates
extern NSString *const kCustomAttributedStringKeyColorLink;
extern NSString *const kCustomAttributedStringKeyColorTempate;
extern NSString *const kCustomAttributedStringKeyColorHtmlTag;
extern NSString *const kCustomAttributedStringKeyColorComment;
extern NSString *const kCustomAttributedStringKeyColorShorthand;

// Public keys, used only for font size adjustment
extern NSString *const kCustomAttributedStringKeyFontBold;
extern NSString *const kCustomAttributedStringKeyFontItalic;
extern NSString *const kCustomAttributedStringKeyFontBoldItalic;
extern NSString *const kCustomAttributedStringKeyFontH2;
extern NSString *const kCustomAttributedStringKeyFontH3;
extern NSString *const kCustomAttributedStringKeyFontH4;
extern NSString *const kCustomAttributedStringKeyFontH5;
extern NSString *const kCustomAttributedStringKeyFontH6;

@interface NSMutableAttributedStringHelper : NSObject

- (instancetype)initWithTheme:(WMFTheme *)theme andPreferredContentSizeCategory:(UIContentSizeCategory)preferredContentSizeCategory;
- (void)addWikitextSyntaxFormattingToNSMutableAttributedString:(NSMutableAttributedString *)mutAttributedString searchRange:(NSRange)searchRange theme:(WMFTheme *)theme;
- (void)recalculateAttributesAfterThemeOrFontSizeChangeWithTheme:(WMFTheme *)theme andPreferredContentSizeCategory:(UIContentSizeCategory)preferredContentSizeCategory;

@end

NS_ASSUME_NONNULL_END
