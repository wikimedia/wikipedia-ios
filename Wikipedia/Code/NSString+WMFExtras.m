#import "NSString+WMFExtras.h"
#import <hpple/TFHpple.h>
#import <CommonCrypto/CommonDigest.h>
#import "SessionSingleton.h"
#import "MWLanguageInfo.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NSString+WMFHTMLParsing.h"

@implementation NSString (WMFExtras)

- (NSString *)wmf_safeSubstringToIndex:(NSUInteger)index {
    return [self substringToIndex:MIN(self.length, index)];
}

- (NSString *)wmf_safeSubstringFromIndex:(NSUInteger)index {
    return [self substringFromIndex:MIN(index, self.length - 1)];
}

+ (NSCharacterSet *)wmf_UTF8StringAllowedCharacterSet {
    static NSCharacterSet *wmf_UTF8StringAllowedCharacterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *URLQueryAllowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [URLQueryAllowedCharacterSet removeCharactersInString:@";/?:@&=$+{}<>,"];
        wmf_UTF8StringAllowedCharacterSet = [URLQueryAllowedCharacterSet copy];
    });
    return wmf_UTF8StringAllowedCharacterSet;
}

- (NSString *)wmf_UTF8StringWithPercentEscapes {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSString wmf_UTF8StringAllowedCharacterSet]];
}

- (NSString *)wmf_schemelessURL {
    NSRange dividerRange = [self rangeOfString:@"://"];
    if (dividerRange.location == NSNotFound) {
        return self;
    }
    NSUInteger divide = NSMaxRange(dividerRange) - 2;
    //NSString *scheme = [self substringToIndex:divide];
    NSString *path = [self substringFromIndex:divide];
    return path;
}

- (NSString *)wmf_asMIMEType {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                                        (__bridge CFStringRef)self,
                                                                                        NULL);
    return (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
}

- (NSDate *)wmf_iso8601Date {
    return [[NSDateFormatter wmf_iso8601Formatter] dateFromString:self];
}

- (nonnull NSAttributedString *)wmf_attributedStringByRemovingHTMLWithFont:(nonnull UIFont *)font linkFont:(nonnull UIFont *)linkFont {
    // Strips html from string with xpath / hpple.
    if (self.length == 0) {
        return [[NSAttributedString alloc] initWithString:self attributes:nil];
    }

    static NSRegularExpression *tagRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"(<[^>]*>)([^<]*)";
        tagRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                             options:NSRegularExpressionCaseInsensitive
                                                               error:nil];
    });

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
    __block BOOL shouldTrimLeadingWhitespace = YES;
    [tagRegex enumerateMatchesInString:self
                               options:0
                                 range:NSMakeRange(0, self.length)
                            usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                *stop = false;
                                NSString *tagContents = [[[[[tagRegex replacementStringForResult:result inString:self offset:0 template:@"$2"] wmf_stringByRemovingBracketedContent] wmf_stringByDecodingHTMLNonBreakingSpaces] wmf_stringByDecodingHTMLAndpersands] wmf_stringByDecodingHTMLLessThanAndGreaterThan];
                                if (!tagContents) {
                                    return;
                                }
                                if (shouldTrimLeadingWhitespace) {
                                    shouldTrimLeadingWhitespace = NO;
                                    NSRange range = [tagContents rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSAnchoredSearch];
                                    while (range.length > 0) {
                                        tagContents = [tagContents stringByReplacingCharactersInRange:range withString:@""];
                                        range = [tagContents rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSAnchoredSearch];
                                    }
                                }
                                NSString *tag = [[tagRegex replacementStringForResult:result inString:self offset:0 template:@"$1"] lowercaseString];
                                NSDictionary *attributes = nil;
                                if ([tag hasPrefix:@"<a"] && linkFont) {
                                    attributes = @{NSFontAttributeName: linkFont};
                                } else if (font) {
                                    attributes = @{NSFontAttributeName: font};
                                }
                                NSAttributedString *attributedNode = [[NSAttributedString alloc] initWithString:tagContents attributes:attributes];
                                [attributedString appendAttributedString:attributedNode];
                            }];
    return [attributedString copy];
}

- (NSString *)wmf_stringByRemovingHTML {
    // Strips html from string with xpath / hpple.
    if (!self || (self.length == 0)) {
        return self;
    }
    NSData *stringData = [self dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:stringData];
    NSArray *textNodes = [parser searchWithXPathQuery:@"//text()"];
    NSMutableArray *results = @[].mutableCopy;
    for (TFHppleElement *node in textNodes) {
        if (node.isTextNode) {
            [results addObject:node.raw];
        }
    }

    NSString *result = [results componentsJoinedByString:@""];

    // Also decode any "&amp;" strings.
    result = [result wmf_stringByDecodingHTMLAndpersands];

    return result;
}

- (NSString *)wmf_randomlyRepeatMaxTimes:(NSUInteger)maxTimes;
{
    float (^rnd)() = ^() {
        return (float)(rand() % (maxTimes - 1) + 1);
    };

    NSString *randStr = [@"" stringByPaddingToLength:rnd() * [self length] withString:self startingAtIndex:0];

    return [NSString stringWithFormat:@"<%@>", [randStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
}

- (NSString *)wmf_stringByReplacingUnderscoresWithSpaces {
    return [self stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

- (NSString *)wmf_stringByReplacingSpacesWithUnderscores {
    return [self stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

- (NSString *)wmf_stringByCapitalizingFirstCharacter {
    // Capitalize first character of WikiData description.
    if (self.length > 1) {
        NSString *firstChar = [self substringToIndex:1];
        NSString *remainingChars = [self substringFromIndex:1];
        NSLocale *locale = [self getLocaleForCurrentSearchDomain];
        firstChar = [firstChar capitalizedStringWithLocale:locale];
        return [firstChar stringByAppendingString:remainingChars];
    }
    return self;
}

- (NSLocale *)getLocaleForCurrentSearchDomain {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *localeCache;
    dispatch_once(&onceToken, ^{
        localeCache = [NSMutableDictionary dictionaryWithCapacity:1];
    });

    NSString *domain = [SessionSingleton sharedInstance].currentArticleSiteURL.wmf_language;

    MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:domain];

    NSString *code = languageInfo.code;

    NSLocale *locale = nil;

    if (!code) {
        return [NSLocale currentLocale];
    }

    locale = [localeCache objectForKey:code];
    if (locale) {
        return locale;
    }

    if ([[NSLocale availableLocaleIdentifiers] containsObject:code]) {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:code];
    }

    if (!locale) {
        locale = [NSLocale currentLocale];
    }

    [localeCache setObject:locale forKey:code];

    return locale;
}

- (BOOL)wmf_containsString:(NSString *)string {
    return [self wmf_containsString:string options:NSLiteralSearch];
}

- (BOOL)wmf_caseInsensitiveContainsString:(NSString *)string {
    return [self wmf_containsString:string options:NSCaseInsensitiveSearch];
}

- (BOOL)wmf_containsString:(NSString *)string options:(NSStringCompareOptions)options {
    return [self rangeOfString:string options:options].location == NSNotFound ? NO : YES;
}

- (BOOL)wmf_isEqualToStringIgnoringCase:(NSString *)string {
    return (NSOrderedSame == [self caseInsensitiveCompare:string]);
}

- (NSString *)wmf_trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)wmf_substringBeforeString:(NSString *)string {
    return [[self componentsSeparatedByString:string] firstObject];
}

- (NSString *)wmf_substringAfterString:(NSString *)string {
    NSArray *components = [self componentsSeparatedByString:string];
    if ([components count] > 2) {
        return components[1];
    } else {
        return [components lastObject];
    }
}

@end
