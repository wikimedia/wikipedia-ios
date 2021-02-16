#import <WMF/NSString+WMFExtras.h>
#import <CommonCrypto/CommonDigest.h>
@import MobileCoreServices;
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/WMF-Swift.h>

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

- (NSString *)wmf_randomlyRepeatMaxTimes:(NSUInteger)maxTimes;
{
    float (^rnd)(void) = ^() {
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

- (NSString *)wmf_stringBySanitizingForJavaScript {
    NSRegularExpression *regex = [NSRegularExpression wmf_charactersToEscapeForJSRegex];
    NSMutableString *mutableSelf = [self mutableCopy];
    __block NSInteger offset = 0;
    [regex enumerateMatchesInString:self
                            options:0
                              range:NSMakeRange(0, self.length)
                         usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                             NSInteger indexForBackslash = result.range.location + offset;
                             if (indexForBackslash >= mutableSelf.length) {
                                 return;
                             }
                             [mutableSelf insertString:@"\\" atIndex:indexForBackslash];
                             offset += 1;
                         }];
    return mutableSelf;
}

- (NSString *)wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:(nullable NSString *)wikipediaLanguage {
    // Capitalize first character of WikiData description.
    if (self.length > 1) {
        NSString *firstChar = [self substringToIndex:1];
        NSString *remainingChars = [self substringFromIndex:1];
        NSLocale *locale = [NSLocale wmf_localeForWikipediaLanguage:wikipediaLanguage];
        firstChar = [firstChar capitalizedStringWithLocale:locale];
        return [firstChar stringByAppendingString:remainingChars];
    }
    return self;
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
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
