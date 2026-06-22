#import <WMF/NSString+WMFHTMLParsing.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/WMFNumberOfExtractCharacters.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSRegularExpression+HTML.h>
#import <WMF/NSCharacterSet+WMFExtras.h>
#import <WMF/NSCharacterSet+WMFLinkParsing.h>
#import "WMF/WMFHTMLElement.h"
@import CoreText;

@interface NSMutableAttributedString (WMFListHandling)
- (NSInteger)performReplacementsForListElement:(nonnull WMFHTMLElement *)listElement currentList:(nullable WMFHTMLElement *)currentList withAttributes:(nullable NSDictionary *)attributes listIndex:(NSInteger)index replacementOffset:(NSInteger)offset;
@end

@implementation NSString (WMFHTMLParsing)

- (NSString *)wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation {
    NSString *result = [self wmf_stringByCollapsingAllWhitespaceToSingleSpaces];
    result = [result wmf_stringByRemovingWhiteSpaceBeforePeriodsCommasSemicolonsAndDashes];
    result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return result;
}

#pragma mark - String simplification and cleanup

- (NSString *)wmf_shareSnippetFromText {
    return [[[[[[self wmf_stringByDecodingHTMLEntities]
        wmf_stringByCollapsingConsecutiveNewlines]
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

- (NSString *)wmf_summaryFromText {
    // Cleanups which need to happen before string is shortened.
    NSString *output = [self wmf_stringByRecursivelyRemovingParenthesizedContent];
    output = [output wmf_stringByRemovingBracketedContent];

    // Now ok to shorten so remaining cleanups are faster.
    output = [output wmf_safeSubstringToIndex:WMFNumberOfExtractCharacters];

    // Cleanups safe to do on shortened string.
    return [[[[output wmf_stringByDecodingHTMLEntities]
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

- (void)wmf_enumerateHTMLTagsWithBlock:(void (^)(NSString *tagName, NSString *tagAttributes, NSRange range))block {
    NSRegularExpression *tagRegex = [NSRegularExpression wmf_HTMLTagRegularExpression];
    [tagRegex enumerateMatchesInString:self
                               options:0
                                 range:NSMakeRange(0, self.length)
                            usingBlock:^(NSTextCheckingResult *_Nullable tagResult, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                NSString *tagName = [tagRegex replacementStringForResult:tagResult inString:self offset:0 template:@"$1"];
                                NSString *tagAttributes = [tagRegex replacementStringForResult:tagResult inString:self offset:0 template:@"$2"];
                                block(tagName, tagAttributes, tagResult.range);
                            }];
}

- (void)wmf_enumerateHTMLEntitiesWithBlock:(void (^)(NSString *entityName, NSRange range))block {
    NSRegularExpression *entityRegex = [NSRegularExpression wmf_HTMLEntityRegularExpression];
    [entityRegex enumerateMatchesInString:self
                                  options:0
                                    range:NSMakeRange(0, self.length)
                               usingBlock:^(NSTextCheckingResult *_Nullable entityResult, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                   NSString *entityName = [entityRegex replacementStringForResult:entityResult inString:self offset:0 template:@"$1"];
                                   block(entityName, entityResult.range);
                               }];
}

- (NSString *)wmf_stringByDecodingHTMLEntities {
    static NSDictionary *entityReplacements;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        entityReplacements = @{@"amp": @"&", @"nbsp": @" ", @"gt": @">", @"lt": @"<", @"apos": @"'", @"quot": @"\"", @"ndash": @"\u2013", @"mdash": @"\u2014", @"#8722": @"\u2212"};
    });
    NSMutableString *mutableSelf = [self mutableCopy];
    __block NSInteger offset = 0;
    [self wmf_enumerateHTMLEntitiesWithBlock:^(NSString *entityName, NSRange range) {
        entityName = [entityName lowercaseString];
        NSString *replacement = entityReplacements[entityName] ?: @"";
        [mutableSelf replaceCharactersInRange:NSMakeRange(range.location + offset, range.length) withString:replacement];
        offset += replacement.length - range.length;
        ;
    }];
    return mutableSelf;
}

- (nonnull NSString *)wmf_stringByRemovingHTMLWithParsingBlock:(nullable void (^)(NSString *lowercasedHTMLTagName, BOOL isEndTag, NSString *HTMLTagAttributes, NSInteger offset, NSInteger currentLocation))parsingBlock {
    __block NSInteger offset = 0;

    NSMutableString *cleanedString = [self mutableCopy];

    __block NSInteger plainTextStartLocation = 0;
    __block NSInteger tagToRemoveStartLocation = NSNotFound;

    static NSSet<NSString *> *tagsToRemove;
    static dispatch_once_t tagsToRemoveOnceToken;
    dispatch_once(&tagsToRemoveOnceToken, ^{
        tagsToRemove = [NSSet setWithObjects:@"script", @"style", nil];
    });

    [self wmf_enumerateHTMLTagsWithBlock:^(NSString *HTMLTagName, NSString *HTMLTagAttributes, NSRange range) {
        HTMLTagName = [HTMLTagName lowercaseString];
        BOOL isEnd = false;
        if ([HTMLTagName hasPrefix:@"/"]) {
            isEnd = true;
            HTMLTagName = [HTMLTagName substringFromIndex:1];
        }
        if ([tagsToRemove containsObject:HTMLTagName]) {
            if (isEnd) {
                if (tagToRemoveStartLocation != NSNotFound) {
                    NSInteger length = range.location + range.length - tagToRemoveStartLocation;
                    [cleanedString replaceCharactersInRange:NSMakeRange(tagToRemoveStartLocation + offset, length) withString:@""];
                    offset -= length;
                    tagToRemoveStartLocation = NSNotFound;
                    return;
                }
                return;
            } else {
                tagToRemoveStartLocation = range.location;
                return;
            }
        }
        if (tagToRemoveStartLocation != NSNotFound) {
            return;
        }
        NSString *replacement = [HTMLTagName isEqualToString:@"br"] || [HTMLTagName isEqualToString:@"br/"] ? @"\n" : @"";
        [cleanedString replaceCharactersInRange:NSMakeRange(range.location + offset, range.length) withString:replacement];
        offset -= (range.length - replacement.length);

        NSInteger currentLocation = range.location + range.length + offset;

        if (currentLocation > plainTextStartLocation) {
            NSRange plainTextRange = NSMakeRange(plainTextStartLocation, currentLocation - plainTextStartLocation);
            NSString *plainText = [cleanedString substringWithRange:plainTextRange];
            NSString *cleanedSubstring = [plainText wmf_stringByDecodingHTMLEntities];
            [cleanedString replaceCharactersInRange:plainTextRange withString:cleanedSubstring];
            NSInteger delta = cleanedSubstring.length - plainText.length;
            offset += delta;
            currentLocation += delta;
            plainTextStartLocation = currentLocation;
        }

        if (parsingBlock) {
            parsingBlock(HTMLTagName, isEnd, HTMLTagAttributes, offset, currentLocation);
        }
    }];

    if (cleanedString.length > plainTextStartLocation) {
        NSRange plainTextRange = NSMakeRange(plainTextStartLocation, cleanedString.length - plainTextStartLocation);
        NSString *plainText = [cleanedString substringWithRange:plainTextRange];
        NSString *cleanedSubstring = [plainText wmf_stringByDecodingHTMLEntities];
        [cleanedString replaceCharactersInRange:plainTextRange withString:cleanedSubstring];
    }
    return cleanedString;
}

- (nonnull NSString *)wmf_stringByRemovingHTML {
    return [self wmf_stringByRemovingHTMLWithParsingBlock:NULL];
}

@end

@implementation NSMutableAttributedString (WMFListHandling)

- (NSInteger)performReplacementsForListElement:(nonnull WMFHTMLElement *)listElement currentList:(nullable WMFHTMLElement *)currentList withAttributes:(nullable NSDictionary *)listAttributes listIndex:(NSInteger)index replacementOffset:(NSInteger)offset {
    __block NSInteger offsetDelta = 0;
    if ([listElement.tagName isEqualToString:@"ul"] || [listElement.tagName isEqualToString:@"ol"]) {
        currentList = listElement;
    } else if (currentList && [listElement.tagName isEqualToString:@"li"]) {
        NSString *spaces = [@"" stringByPaddingToLength:listElement.nestingDepth * 3 withString:@" " startingAtIndex:0];
        NSString *number = [NSString stringWithFormat:@"\n%@%lu. ", spaces, index + 1];
        NSString *bulletPoint = [NSString stringWithFormat:@"\n%@• ", spaces];
        NSString *bulletPointOrNumberWithNewline = [currentList.tagName isEqualToString:@"ol"] ? number : bulletPoint;
        NSAttributedString *stringToInsert = [[NSAttributedString alloc] initWithString:bulletPointOrNumberWithNewline attributes:listAttributes];
        [self insertAttributedString:stringToInsert atIndex:listElement.startLocation + offset + offsetDelta];
        offsetDelta += stringToInsert.length;
    }
    [listElement.children enumerateObjectsUsingBlock:^(WMFHTMLElement *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        offsetDelta += [self performReplacementsForListElement:obj currentList:currentList withAttributes:listAttributes listIndex:idx replacementOffset:offset + offsetDelta];
    }];
    return offsetDelta;
}

@end
