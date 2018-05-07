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

@end
