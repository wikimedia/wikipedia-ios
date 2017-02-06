#import "NSString+WMFHTMLParsing.h"
#import <hpple/TFHpple.h>
#import "NSString+WMFExtras.h"
#import "WMFNumberOfExtractCharacters.h"

@implementation NSString (WMFHTMLParsing)

- (NSArray *)wmf_htmlTextNodes {
    return [[[[TFHpple alloc]
        initWithHTMLData:[self dataUsingEncoding:NSUTF8StringEncoding]]
        searchWithXPathQuery:@"//text()"]
        valueForKey:WMF_SAFE_KEYPATH([TFHppleElement new], content)];
}

- (NSString *)wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation {
    NSString *result = [self wmf_stringByCollapsingAllWhitespaceToSingleSpaces];
    result = [result wmf_stringByRemovingWhiteSpaceBeforePeriodsCommasSemicolonsAndDashes];
    result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return result;
}

- (NSString *)wmf_joinedHtmlTextNodes {
    return [self wmf_joinedHtmlTextNodesWithDelimiter:@" "];
}

- (NSString *)wmf_joinedHtmlTextNodesWithDelimiter:(NSString *)delimiter {
    return [[self wmf_htmlTextNodes] componentsJoinedByString:delimiter];
}

#pragma mark - String simplification and cleanup

- (NSString *)wmf_shareSnippetFromText {
    return [[[[[[[[self wmf_stringByDecodingHTMLAndpersands]
        wmf_stringByDecodingHTMLLessThanAndGreaterThan]
        wmf_stringByCollapsingConsecutiveNewlines]
        wmf_stringByRecursivelyRemovingParenthesizedContent]
        wmf_stringByRemovingBracketedContent]
        wmf_stringByRemovingWhiteSpaceBeforePeriodsCommasSemicolonsAndDashes]
        wmf_stringByCollapsingConsecutiveSpaces]
        wmf_stringByRemovingLeadingOrTrailingSpacesNewlinesOrColons];
}

- (NSString *)wmf_stringByCollapsingConsecutiveNewlines {
    static NSRegularExpression *newlinesRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        newlinesRegex = [NSRegularExpression regularExpressionWithPattern:@"\n{2,}"
                                                                  options:0
                                                                    error:nil];
    });
    return [newlinesRegex stringByReplacingMatchesInString:self
                                                   options:0
                                                     range:NSMakeRange(0, self.length)
                                              withTemplate:@"\n"];
}

- (NSString *)wmf_stringByRecursivelyRemovingParenthesizedContent {
    // We probably don't want to handle ideographic parens
    static NSRegularExpression *parensRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        parensRegex = [NSRegularExpression
            regularExpressionWithPattern:@"[(][^()]+[)]"
                                 options:0
                                   error:nil];
    });

    NSString *string = [self copy];
    NSString *oldResult;
    NSRange range;
    do {
        oldResult = [string copy];
        range = NSMakeRange(0, string.length);
        string = [parensRegex stringByReplacingMatchesInString:string
                                                       options:0
                                                         range:range
                                                  withTemplate:@""];
    } while (![oldResult isEqualToString:string]);
    return string;
}

- (NSString *)wmf_stringByRemovingBracketedContent {
    // We don't care about ideographic brackets
    // Nested bracketing unseen thus far
    static NSRegularExpression *bracketedRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bracketedRegex = [NSRegularExpression
            regularExpressionWithPattern:@"\\[[^]]+]"
                                 options:0
                                   error:nil];
    });

    return [bracketedRegex stringByReplacingMatchesInString:self
                                                    options:0
                                                      range:NSMakeRange(0, self.length)
                                               withTemplate:@""];
}

- (NSString *)wmf_stringByRemovingWhiteSpaceBeforePeriodsCommasSemicolonsAndDashes {
    // Ideographic stops from TextExtracts, which were from OpenSearch
    static NSRegularExpression *spacePeriodRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        spacePeriodRegex = [NSRegularExpression
            regularExpressionWithPattern:@"\\s+([\\.。．｡,、;\\-\u2014])"
                                 options:0
                                   error:nil];
    });

    return [spacePeriodRegex stringByReplacingMatchesInString:self
                                                      options:0
                                                        range:NSMakeRange(0, self.length)
                                                 withTemplate:@"$1"];
}

- (NSString *)wmf_stringByCollapsingConsecutiveSpaces {
    // In practice, we rarely care about doubled up whitespace in the
    // string except for the actual space character
    static NSRegularExpression *spacesRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        spacesRegex = [NSRegularExpression
            regularExpressionWithPattern:@" {2,}"
                                 options:0
                                   error:nil];
    });

    return [spacesRegex stringByReplacingMatchesInString:self
                                                 options:0
                                                   range:NSMakeRange(0, self.length)
                                            withTemplate:@" "];
}

- (NSString *)wmf_stringByCollapsingAllWhitespaceToSingleSpaces {
    static NSRegularExpression *whitespaceRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whitespaceRegex = [NSRegularExpression
            regularExpressionWithPattern:@"\\s+"
                                 options:0
                                   error:nil];
    });

    return [whitespaceRegex stringByReplacingMatchesInString:self
                                                     options:0
                                                       range:NSMakeRange(0, self.length)
                                                withTemplate:@" "];
}

- (NSString *)wmf_stringByRemovingLeadingOrTrailingSpacesNewlinesOrColons {
    // Note about trailing colon characters: they usually look strange if kept,
    // and removing them (plus spaces and newlines) doesn't often create merged
    // words that look bad - these are usually at tag boundaries. For Latinized
    // langs sometimes this means words like "include" finish the snippet.
    // But as a matter of markup structure, something like a <p> tag
    // shouldn't be </p> closed until something like <ul>...</ul> is closed.
    // In fact, some sections have this layout, and some do not.
    static NSRegularExpression *leadTrailColonRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        leadTrailColonRegex = [NSRegularExpression
            regularExpressionWithPattern:@"^[\\s\n]+|[\\s\n:]+$"
                                 options:0
                                   error:nil];
    });

    return [leadTrailColonRegex stringByReplacingMatchesInString:self
                                                         options:0
                                                           range:NSMakeRange(0, self.length)
                                                    withTemplate:@""];
}

- (NSString *)wmf_stringByDecodingHTMLNonBreakingSpaces {
    return [self stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
}

- (NSString *)wmf_stringByDecodingHTMLAndpersands {
    return [self stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
}

- (NSString *)wmf_stringByDecodingHTMLLessThanAndGreaterThan {
    return [[self stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"]
        stringByReplacingOccurrencesOfString:@"&lt;"
                                  withString:@"<"];
}

- (NSString *)wmf_summaryFromText {
    // Cleanups which need to happen before string is shortened.
    NSString *output = [self wmf_stringByRecursivelyRemovingParenthesizedContent];
    output = [output wmf_stringByRemovingBracketedContent];

    // Now ok to shorten so remaining cleanups are faster.
    output = [output wmf_safeSubstringToIndex:WMFNumberOfExtractCharacters];

    // Cleanups safe to do on shortened string.
    return [[[[[[output wmf_stringByDecodingHTMLAndpersands]
        wmf_stringByDecodingHTMLLessThanAndGreaterThan]
        wmf_stringByDecodingHTMLNonBreakingSpaces]
        wmf_stringByCollapsingAllWhitespaceToSingleSpaces]
        wmf_stringByRemovingWhiteSpaceBeforePeriodsCommasSemicolonsAndDashes]
        wmf_stringByRemovingLeadingOrTrailingSpacesNewlinesOrColons];
}

- (void)wmf_enumerateHTMLImageTagContentsWithHandler:(nonnull void (^)(NSString *imageTagContents, NSRange range))handler {
    static NSRegularExpression *imageTagRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"(?:<img\\s)([^>]*)(?:>)";
        imageTagRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                  options:NSRegularExpressionCaseInsensitive
                                                                    error:nil];
    });

    [imageTagRegex enumerateMatchesInString:self
                                    options:0
                                      range:NSMakeRange(0, self.length)
                                 usingBlock:^(NSTextCheckingResult *_Nullable imageTagResult, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                     //get just the image tag contents - everything between <img and >
                                     NSString *imageTagContents = [imageTagRegex replacementStringForResult:imageTagResult inString:self offset:0 template:@"$1"];
                                     handler(imageTagContents, imageTagResult.range);
                                     *stop = false;
                                 }];
}

- (NSAttributedString *)wmf_attributedStringWithLinksFromHTMLTags {
    static NSRegularExpression *tagRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"(?:<)([\\/a-z0-9]+)(?:\\s?)([^>]*)(?:>)";
        tagRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                  options:NSRegularExpressionCaseInsensitive
                                                                    error:nil];
    });
    
    static NSRegularExpression *hrefRegex;
    static dispatch_once_t hrefOnceToken;
    dispatch_once(&hrefOnceToken, ^{
        NSString *hrefPattern = @"href=[\"']?((?:.(?![\"']?\\s+(?:\\S+)=|[>\"']))+.)[\"']?";
        hrefRegex = [NSRegularExpression regularExpressionWithPattern:hrefPattern options:NSRegularExpressionCaseInsensitive error:nil];
    });
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    __block NSInteger location = 0;
    __block NSURL *linkURL = nil;
    __block NSMutableString *linkString = nil;
    [tagRegex enumerateMatchesInString:self
                                    options:0
                                      range:NSMakeRange(0, self.length)
                                 usingBlock:^(NSTextCheckingResult *_Nullable tagResult, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                     NSString *tagName = [[tagRegex replacementStringForResult:tagResult inString:self offset:0 template:@"$1"] lowercaseString];
                                     
                                     NSInteger nonMatchingLength = tagResult.range.location - location;
                                     if (nonMatchingLength > 0) {
                                         NSString *nonMatchingString = [self substringWithRange:NSMakeRange(location, nonMatchingLength)];
                                         if (linkString) {
                                             [linkString appendString:nonMatchingString];
                                         } else {
                                             NSAttributedString *nonMatchingAttributedString = [[NSAttributedString alloc] initWithString:nonMatchingString];
                                             [attributedString appendAttributedString:nonMatchingAttributedString];
                                         }
                                     }
                                     
                                     if ([tagName isEqualToString:@"a"]) {
                                         NSString *tagContents = [tagRegex replacementStringForResult:tagResult inString:self offset:0 template:@"$2"];
                                         [hrefRegex enumerateMatchesInString:tagContents options:0 range:NSMakeRange(0, tagContents.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
                                              NSString *URLString = [hrefRegex replacementStringForResult:result inString:tagContents offset:0 template:@"$1"];
                                             linkURL = [NSURL URLWithString:URLString];
                                         }];
                                         
                                         if (linkURL) {
                                             linkString = [[NSMutableString alloc] init];
                                         }
                                     } else if ([tagName isEqualToString:@"/a"]) {
                                         NSMutableAttributedString *linkAttributedString = nil;
                                         if (linkString) {
                                             linkAttributedString = [[NSMutableAttributedString alloc] initWithString:linkString];
                                         }
                                         if (linkURL) {
                                             [linkAttributedString addAttribute:NSLinkAttributeName value:linkURL range: NSMakeRange(0, linkAttributedString.length)];
                                         }
                                         if (linkAttributedString) {
                                             [attributedString appendAttributedString:linkAttributedString];
                                         }
                                         linkString = nil;
                                         linkURL = nil;
                                     }
                                     location = tagResult.range.location + tagResult.range.length;
                                 }];
    NSInteger nonMatchingLength = self.length - location;
    if (nonMatchingLength > 0) {
        NSString *nonMatchingString = [self substringWithRange:NSMakeRange(location, nonMatchingLength)];
        NSAttributedString *nonMatchingAttributedString = [[NSAttributedString alloc] initWithString:nonMatchingString];
        [attributedString appendAttributedString:nonMatchingAttributedString];
    }
    
    return attributedString;
}
@end
