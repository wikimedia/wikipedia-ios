#import "NSString+WMFImageProxy.h"
#import "NSString+WMFExtras.h"

@implementation NSString (WMFImageProxy)

- (NSString*)wmf_stringPercentEncodedWithLocalhostProxyPrefix {
    return [NSString stringWithFormat:@"http://localhost:8080/imageProxy?originalSrc=%@", [self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString*)wmf_replaceURLsWithLocalhostProxyURLsInSrcsetValue:(NSString*)srcsetValue {
    NSAssert(![srcsetValue containsString:@"<"] && ![srcsetValue containsString:@">"], @"This method should only operate on an html img tag's 'srcset' value substring - not entire image tags.");

    NSArray* pairs         = [srcsetValue componentsSeparatedByString:@","];
    NSMutableArray* output = [[NSMutableArray alloc] init];
    for (NSString* pair in pairs) {
        NSString* trimmedPair = [pair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray* parts        = [trimmedPair componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (parts.count == 2) {
            NSString* url     = parts[0];
            NSString* density = parts[1];
            [output addObject:[NSString stringWithFormat:@"%@ %@", [url wmf_stringPercentEncodedWithLocalhostProxyPrefix], density]];
        } else {
            [output addObject:pair];
        }
    }
    return [output componentsJoinedByString:@", "];
}

- (NSString*)wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs {
    static NSRegularExpression* regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"(<img\\s+[^>]*src\\=)(?:\")(.*?)(?:\")(.*?[^>]*)(>)";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:nil];
    });

    NSMutableString* mutableSelf = [self mutableCopy];

    NSArray* matches = [regex matchesInString:mutableSelf options:0 range:NSMakeRange(0, [mutableSelf length])];

    NSInteger offset = 0;
    for (NSTextCheckingResult* result in matches) {
        NSRange resultRange = [result range];
        resultRange.location += offset;

        NSString* opener = [regex replacementStringForResult:result
                                                    inString:mutableSelf
                                                      offset:offset
                                                    template:@"$1"];

        NSString* srcURL = [regex replacementStringForResult:result
                                                    inString:mutableSelf
                                                      offset:offset
                                                    template:@"$2"];

        NSString* nonSrcPartsOfImgTag = [regex replacementStringForResult:result
                                                                 inString:mutableSelf
                                                                   offset:offset
                                                                 template:@"$3"];

        NSString* closer = [regex replacementStringForResult:result
                                                    inString:mutableSelf
                                                      offset:offset
                                                    template:@"$4"];

        if ([srcURL wmf_trim].length > 0) {
            srcURL = [srcURL wmf_stringPercentEncodedWithLocalhostProxyPrefix];
        }

        NSString* replacement = [NSString stringWithFormat:@"%@\"%@\"%@%@",
                                 opener,
                                 srcURL,
                                 [nonSrcPartsOfImgTag wmf_stringWithSrcsetURLsChangedToLocalhostProxyURLs],
                                 closer
                                ];

        [mutableSelf replaceCharactersInRange:resultRange withString:replacement];

        offset += [replacement length] - resultRange.length;
    }

    return mutableSelf;
}

- (NSString*)wmf_stringWithSrcsetURLsChangedToLocalhostProxyURLs {
    NSAssert(![self containsString:@"<"] && ![self containsString:@">"], @"This method should only operate on an html img tag's 'srcset' key/value substring - not entire image tags.");

    static NSRegularExpression* regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"(.+?)(srcset\\=)(?:\")(.+?)(?:\")(.*?)";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:nil];
    });

    NSMutableString* mutableSelf = [self mutableCopy];

    NSArray* matches = [regex matchesInString:mutableSelf options:0 range:NSMakeRange(0, [mutableSelf length])];

    NSInteger offset = 0;
    for (NSTextCheckingResult* result in matches) {
        NSRange resultRange = [result range];
        resultRange.location += offset;

        NSString* before = [regex replacementStringForResult:result
                                                    inString:mutableSelf
                                                      offset:offset
                                                    template:@"$1"];

        NSString* srcsetKey = [regex replacementStringForResult:result
                                                       inString:mutableSelf
                                                         offset:offset
                                                       template:@"$2"];

        NSString* srcsetValue = [regex replacementStringForResult:result
                                                         inString:mutableSelf
                                                           offset:offset
                                                         template:@"$3"];

        NSString* after = [regex replacementStringForResult:result
                                                   inString:mutableSelf
                                                     offset:offset
                                                   template:@"$4"];

        NSString* replacement = [NSString stringWithFormat:@"%@%@\"%@\"%@",
                                 before,
                                 srcsetKey,
                                 [self wmf_replaceURLsWithLocalhostProxyURLsInSrcsetValue:srcsetValue],
                                 after
                                ];

        [mutableSelf replaceCharactersInRange:resultRange withString:replacement];

        offset += [replacement length] - resultRange.length;
    }
    return mutableSelf;
}

@end
