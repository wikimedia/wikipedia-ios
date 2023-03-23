#import <Foundation/Foundation.h>
@import UIKit;
@class WMFTheme;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kCustomAttributedStringKeyWikitextBold;
extern NSString * const kCustomAttributedStringKeyWikitextItalic;
extern NSString * const kCustomAttributedStringKeyWikitextBoldAndItalic;
extern NSString * const kCustomAttributedStringKeyWikitextLink;
extern NSString * const kCustomAttributedStringKeyWikitextImage;
extern NSString * const kCustomAttributedStringKeyWikitextTemplate;
extern NSString * const kCustomAttributedStringKeyWikitextRef;
extern NSString * const kCustomAttributedStringKeyWikitextRefWithAttributes;
extern NSString * const kCustomAttributedStringKeyWikitextRefSelfClosing;
extern NSString * const kCustomAttributedStringKeyWikitextSuperscript;
extern NSString * const kCustomAttributedStringKeyWikitextSubscript;
extern NSString * const kCustomAttributedStringKeyWikitextUnderline;
extern NSString * const kCustomAttributedStringKeyWikitextStrikethrough;
extern NSString * const kCustomAttributedStringKeyWikitextBullet;
extern NSString * const kCustomAttributedStringKeyWikitextNumber;
extern NSString * const kCustomAttributedStringKeyWikitextH2;
extern NSString * const kCustomAttributedStringKeyWikitextH3;
extern NSString * const kCustomAttributedStringKeyWikitextH4;
extern NSString * const kCustomAttributedStringKeyWikitextH5;
extern NSString * const kCustomAttributedStringKeyWikitextH6;
extern NSString * const kCustomAttributedStringKeyWikitextComment;

@interface NSMutableAttributedStringHelper : NSObject

-(instancetype)initWithTheme:(WMFTheme *)theme;
-(void)addWikitextSyntaxFormattingToNSMutableAttributedString: (NSMutableAttributedString *)mutAttributedString searchRange: (NSRange)searchRange fontSizeTraitCollection: (UITraitCollection *)fontSizeTraitCollection needsColors: (BOOL)needsColors theme: (WMFTheme *)theme;

@end

NS_ASSUME_NONNULL_END
