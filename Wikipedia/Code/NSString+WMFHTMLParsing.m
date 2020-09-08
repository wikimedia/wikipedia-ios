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

- (NSMutableAttributedString *)wmf_attributedStringFromHTMLWithFont:(UIFont *)font boldFont:(nullable UIFont *)boldFont italicFont:(nullable UIFont *)italicFont boldItalicFont:(nullable UIFont *)boldItalicFont color:(nullable UIColor *)color linkColor:(nullable UIColor *)linkColor handlingLinks:(BOOL)handlingLinks handlingLists:(BOOL)handlingLists handlingSuperSubscripts:(BOOL)handlingSuperSubscripts tagMapping:(nullable NSDictionary<NSString *, NSString *> *)tagMapping additionalTagAttributes:(nullable NSDictionary<NSString *, NSDictionary<NSAttributedStringKey, id> *> *)additionalTagAttributes {
    boldFont = boldFont ?: font;
    italicFont = italicFont ?: font;
    boldItalicFont = boldItalicFont ?: font;
    static NSRegularExpression *hrefRegex;
    static dispatch_once_t hrefOnceToken;
    dispatch_once(&hrefOnceToken, ^{
        NSString *hrefPattern = @"href[\\s]*=[\\s]*[\"']?[\\s]*((?:.(?![\"']?\\s+(?:\\S+)=|[>\"']))+.)[\\s]*[\"']?";
        hrefRegex = [NSRegularExpression regularExpressionWithPattern:hrefPattern options:NSRegularExpressionCaseInsensitive error:nil];
    });

    NSMutableSet<NSString *> *currentTags = [NSMutableSet setWithCapacity:2];
    NSMutableSet<NSURL *> *currentLinks = [NSMutableSet setWithCapacity:1];
    NSMutableArray<NSSet<NSString *> *> *tags = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray<NSSet<NSURL *> *> *links = [NSMutableArray arrayWithCapacity:1];

    NSMutableArray<WMFHTMLElement *> *lists = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray<WMFHTMLElement *> *unclosedListElements = [NSMutableArray arrayWithCapacity:1];

    NSMutableArray<NSValue *> *ranges = [NSMutableArray arrayWithCapacity:1];
    __block NSInteger startLocation = NSNotFound;
    NSString *cleanedString = [self wmf_stringByRemovingHTMLWithParsingBlock:^(NSString *HTMLTagName, BOOL isEndTag, NSString *HTMLTagAttributes, NSInteger offset, NSInteger currentLocation) {
        NSString *mapping = tagMapping[HTMLTagName];
        if (mapping) {
            HTMLTagName = mapping;
        }
        if (startLocation != NSNotFound && currentLocation > startLocation) {
            [ranges addObject:[NSValue valueWithRange:NSMakeRange(startLocation, currentLocation - startLocation)]];
            [tags addObject:[currentTags copy]];
            [links addObject:[currentLinks copy]];
        }
        if (isEndTag) {
            if ([HTMLTagName isEqualToString:@"a"]) {
                [currentLinks removeAllObjects];
            } else if (handlingLists && ([HTMLTagName isEqualToString:@"ul"] || [HTMLTagName isEqualToString:@"ol"] || [HTMLTagName isEqualToString:@"li"])) {
                WMFHTMLElement *lastUnclosedListElement = nil;
                NSInteger index = unclosedListElements.count;
                for (WMFHTMLElement *unclosedListElement in [unclosedListElements reverseObjectEnumerator]) {
                    index -= 1;
                    if ([unclosedListElement.tagName isEqualToString:HTMLTagName]) {
                        lastUnclosedListElement = unclosedListElement;
                        break;
                    }
                }
                if (lastUnclosedListElement != nil) {
                    lastUnclosedListElement.endLocation = currentLocation;
                    [unclosedListElements removeObjectAtIndex:index];
                } else {
                    assert(false);
                }
            }
            [currentTags removeObject:HTMLTagName];
            if ([currentTags count] > 0) {
                startLocation = currentLocation;
            } else {
                startLocation = NSNotFound;
            }
        } else {
            startLocation = currentLocation;
            [currentTags addObject:HTMLTagName];
            if (handlingLinks && [HTMLTagName isEqualToString:@"a"]) {
                [hrefRegex enumerateMatchesInString:HTMLTagAttributes
                                            options:0
                                              range:NSMakeRange(0, HTMLTagAttributes.length)
                                         usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                             NSString *URLString = [hrefRegex replacementStringForResult:result inString:HTMLTagAttributes offset:0 template:@"$1"];
                                             if ([URLString hasPrefix:@"."] || [URLString hasPrefix:@"/"]) {
                                                 URLString = [URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet wmf_relativePathAndFragmentAllowedCharacterSet]];
                                             }
                                             NSURL *linkURL = [NSURL URLWithString:URLString];
                                             if (linkURL) {
                                                 [currentLinks addObject:linkURL];
                                             }
                                         }];
            } else if (handlingLists) {
                if ([HTMLTagName isEqualToString:@"ul"] || [HTMLTagName isEqualToString:@"ol"]) {
                    WMFHTMLElement *list = [[WMFHTMLElement alloc] initWithTagName:HTMLTagName];
                    list.startLocation = startLocation;
                    list.children = [NSMutableArray arrayWithCapacity:2];
                    WMFHTMLElement *lastUnclosedListElement = unclosedListElements.lastObject;
                    if (lastUnclosedListElement) {
                        [lastUnclosedListElement.children addObject:list];
                        list.nestingDepth = lastUnclosedListElement.nestingDepth + 1;
                    } else {
                        list.nestingDepth = 1;
                        [lists addObject:list];
                    }
                    [unclosedListElements addObject:list];
                } else if ([HTMLTagName isEqualToString:@"li"]) {
                    WMFHTMLElement *lastUnclosedListElement = nil;
                    NSInteger index = unclosedListElements.count;
                    for (WMFHTMLElement *unclosedListElement in [unclosedListElements reverseObjectEnumerator]) {
                        index -= 1;
                        if (![unclosedListElement.tagName isEqualToString:@"li"]) {
                            lastUnclosedListElement = unclosedListElement;
                            break;
                        }
                    }
                    if (lastUnclosedListElement == nil) {
                        assert(false);
                        return;
                    }
                    WMFHTMLElement *listItem = [[WMFHTMLElement alloc] initWithTagName:HTMLTagName];
                    listItem.nestingDepth = lastUnclosedListElement.nestingDepth;
                    listItem.startLocation = startLocation;
                    listItem.children = [NSMutableArray arrayWithCapacity:2];
                    [lastUnclosedListElement.children addObject:listItem];
                    [unclosedListElements addObject:listItem];
                }
            }
        }
    }];

    NSMutableDictionary *attribtues = [NSMutableDictionary dictionaryWithCapacity:2];
    if (font) {
        [attribtues setObject:font forKey:NSFontAttributeName];
    }
    if (color) {
        [attribtues setObject:color forKey:NSForegroundColorAttributeName];
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:cleanedString attributes:attribtues];

    NSRange matchingRange = NSMakeRange(NSNotFound, 0);

    [ranges enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSRange range = [obj rangeValue];
        NSSet *tagsForRange = [tags objectAtIndex:idx];
        NSSet *linksForRange = [links objectAtIndex:idx];
        BOOL isItalic = [tagsForRange containsObject:@"i"];
        BOOL isBold = [tagsForRange containsObject:@"b"];
        BOOL isSubscript = [tagsForRange containsObject:@"sub"];
        BOOL isSuperscript = [tagsForRange containsObject:@"sup"];
        if (isItalic && isBold) {
            [attributedString addAttribute:NSFontAttributeName value:boldItalicFont range:range];
        } else if (isItalic) {
            [attributedString addAttribute:NSFontAttributeName value:italicFont range:range];
            if (matchingRange.location != NSNotFound) {
                NSRange intersection = NSIntersectionRange(matchingRange, range);
                if (intersection.length > 0) {
                    [attributedString addAttribute:NSFontAttributeName value:boldItalicFont range:intersection];
                }
            }
        } else if (isBold) {
            [attributedString addAttribute:NSFontAttributeName value:boldFont range:range];
        }

        if (handlingSuperSubscripts) {
            if (isSubscript) {
                [attributedString addAttribute:(NSString *)kCTSuperscriptAttributeName value:[NSNumber numberWithInt:-1] range:range];
            }

            if (isSuperscript) {
                [attributedString addAttribute:(NSString *)kCTSuperscriptAttributeName value:[NSNumber numberWithInt:1] range:range];
            }
        }

        NSURL *linkURL = [linksForRange anyObject];
        if (linkURL) {
            [attributedString addAttribute:NSLinkAttributeName value:linkURL range:range];
            if (linkColor) {
                [attributedString addAttribute:NSForegroundColorAttributeName value:linkColor range:range];
            }
        }

        for (NSString *tag in additionalTagAttributes.allKeys) {
            if (![tagsForRange containsObject:tag]) {
                continue;
            }
            NSDictionary<NSAttributedStringKey, id> *attributes = additionalTagAttributes[tag];
            if (attributes.count == 0) {
                continue;
            }
            [attributedString addAttributes:attributes range:range];
        }
    }];

    NSDictionary *listAttributes = font != nil ? @{NSFontAttributeName: font} : @{};
    __block NSInteger offset = 0;
    [lists enumerateObjectsUsingBlock:^(WMFHTMLElement *_Nonnull list, NSUInteger idx, BOOL *_Nonnull stop) {
        offset += [attributedString performReplacementsForListElement:list currentList:list withAttributes:listAttributes listIndex:0 replacementOffset:offset];
        NSString *newline = @"\n";
        NSAttributedString *attributedNewline = [[NSAttributedString alloc] initWithString:newline attributes:attribtues];
        [attributedString insertAttributedString:attributedNewline atIndex:list.endLocation + offset];
        offset += attributedNewline.length;
    }];

    return attributedString;
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
