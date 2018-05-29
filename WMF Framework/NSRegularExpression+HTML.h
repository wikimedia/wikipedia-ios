#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSRegularExpression (HTML)

// Matches HTML tags
+ (NSRegularExpression *)wmf_HTMLTagRegularExpression;

// Matches HTML entities &amp; &nbsp; etc
+ (NSRegularExpression *)wmf_HTMLEntityRegularExpression;

// Matches ' " ; '
+ (NSRegularExpression *)wmf_charactersToEscapeForJSRegex;

@end

NS_ASSUME_NONNULL_END
