#import <UIKit/UIKit.h>

@interface UIFont (WMF_Style)

+ (UIFont *)wmf_glyphFontOfSize:(CGFloat)fontSize;

/// @return A copy of the receiver whose font size has been multiplied by @c scalar.
- (instancetype)wmf_copyWithSizeScaledBy:(CGFloat)scalar;

+ (UIFont *)wmf_htmlBodyFont;

+ (instancetype)wmf_tableOfContentsSectionFont;
+ (instancetype)wmf_tableOfContentsSubsectionFont;

+ (instancetype)wmf_nearbyTitleFont;
+ (instancetype)wmf_subtitle;
+ (instancetype)wmf_nearbyDistanceFont;

@end
