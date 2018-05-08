#import "NSRegularExpression+HTML.h"

@implementation NSRegularExpression (HTML)

+ (NSRegularExpression *)wmf_HTMLTagRegularExpression {
    static NSRegularExpression *tagRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"(?:<)([\\/a-z0-9]+)(?:\\s?)([^>]*)(?:>)";
        tagRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                             options:NSRegularExpressionCaseInsensitive
                                                               error:nil];
    });
    return tagRegex;
}


+ (NSRegularExpression *)wmf_HTMLEntityRegularExpression {
    static NSRegularExpression *tagRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"&([^\\s;]+);";
        tagRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                             options:NSRegularExpressionCaseInsensitive
                                                               error:nil];
    });
    return tagRegex;
}

+ (NSRegularExpression *)wmf_HTMLRegularExpressionMatchingText:(NSString *)string {
    NSString *pattern = [NSString stringWithFormat:@"(?:(?:^|>)[^>]*)(%@)(?:[^<]*(?:<|$))", string];
    return [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
}

@end
