#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSRegularExpression (HTML)

// Matches HTML tags
+ (NSRegularExpression *)wmf_HTMLTagRegularExpression;

// Matches HTML entities &amp; &nbsp; etc
+ (NSRegularExpression *)wmf_HTMLEntityRegularExpression;

// Matches the provided text between > and < or the start and end of the string
+ (nullable NSRegularExpression *)wmf_HTMLRegularExpressionMatchingText:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
