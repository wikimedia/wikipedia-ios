#import <WMF/NSString+WMFHTMLParsing.h>
#import <hpple/TFHpple.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/WMFNumberOfExtractCharacters.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSRegularExpression+HTML.h>

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
        entityReplacements = @{@"amp": @"&", @"nbsp": @" ", @"gt": @">", @"lt": @"<", @"apos": @"'", @"quot": @"\""};
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

- (nonnull NSString *)wmf_stringByRemovingHTMLWithParsingBlock:(nullable void (^)(NSString *HTMLTagName, NSInteger offset, NSInteger currentLocation))parsingBlock {
    __block NSInteger offset = 0;

    NSMutableString *cleanedString = [self mutableCopy];

    __block NSInteger plainTextStartLocation = 0;

    [self wmf_enumerateHTMLTagsWithBlock:^(NSString *HTMLTagName, NSString *HTMLTagAttributes, NSRange range) {
        [cleanedString replaceCharactersInRange:NSMakeRange(range.location + offset, range.length) withString:@""];
        offset -= range.length;

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
            parsingBlock(HTMLTagName, offset, currentLocation);
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

- (NSAttributedString *)wmf_attributedStringFromHTMLWithFont:(UIFont *)font boldFont:(nullable UIFont *)boldFont italicFont:(nullable UIFont *)italicFont boldItalicFont:(nullable UIFont *)boldItalicFont withAdditionalBoldingForMatchingSubstring:(nullable NSString *)stringToBold {
    return [self wmf_attributedStringFromHTMLWithFont:font boldFont:boldFont italicFont:italicFont boldItalicFont:boldItalicFont withAdditionalBoldingForMatchingSubstring:stringToBold boldLinks:NO];
}

- (NSAttributedString *)wmf_attributedStringFromHTMLWithFont:(UIFont *)font boldFont:(nullable UIFont *)boldFont italicFont:(nullable UIFont *)italicFont boldItalicFont:(nullable UIFont *)boldItalicFont withAdditionalBoldingForMatchingSubstring:(nullable NSString *)stringToBold boldLinks:(BOOL)shouldBoldLinks {
    boldFont = boldFont ?: font;
    italicFont = italicFont ?: font;
    boldItalicFont = boldItalicFont ?: font;

    NSMutableSet<NSString *> *currentTags = [NSMutableSet setWithCapacity:2];
    NSMutableArray<NSSet<NSString *> *> *tags = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray<NSValue *> *ranges = [NSMutableArray arrayWithCapacity:1];
    __block NSInteger startLocation = NSNotFound;
    NSString *cleanedString = [self wmf_stringByRemovingHTMLWithParsingBlock:^(NSString *HTMLTagName, NSInteger offset, NSInteger currentLocation) {
        HTMLTagName = [HTMLTagName lowercaseString];
        if (shouldBoldLinks && [HTMLTagName isEqualToString:@"a"]) {
            HTMLTagName = @"b";
        }
        if (startLocation != NSNotFound && currentLocation > startLocation) {
            [ranges addObject:[NSValue valueWithRange:NSMakeRange(startLocation, currentLocation - startLocation)]];
            [tags addObject:[currentTags copy]];
        }
        if ([HTMLTagName hasPrefix:@"/"] && startLocation != NSNotFound) {
            NSString *closeTagName = [HTMLTagName substringFromIndex:1];
            [currentTags removeObject:closeTagName];
            if ([currentTags count] > 0) {
                startLocation = currentLocation;
            } else {
                startLocation = NSNotFound;
            }
        } else {
            startLocation = currentLocation;
            [currentTags addObject:HTMLTagName];
        }
    }];

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:cleanedString attributes:@{NSFontAttributeName: font}];

    NSRange matchingRange = NSMakeRange(NSNotFound, 0);
    if (stringToBold) {
        matchingRange = [cleanedString rangeOfString:stringToBold options:NSCaseInsensitiveSearch];
        if (matchingRange.location != NSNotFound) {
            [attributedString addAttribute:NSFontAttributeName value:boldFont range:matchingRange];
        }
    }

    [ranges enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSRange range = [obj rangeValue];
        NSSet *tagsForRange = [tags objectAtIndex:idx];
        BOOL isItalic = [tagsForRange containsObject:@"i"];
        BOOL isBold = [tagsForRange containsObject:@"b"];
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
    }];

    return attributedString;
}

- (NSAttributedString *)wmf_attributedStringWithLinksFromHTMLTags {
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
    [self wmf_enumerateHTMLTagsWithBlock:^(NSString *tagName, NSString *tagAttributes, NSRange range) {
        tagName = [tagName lowercaseString];
        NSInteger nonMatchingLength = range.location - location;
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
            [hrefRegex enumerateMatchesInString:tagAttributes
                                        options:0
                                          range:NSMakeRange(0, tagAttributes.length)
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                         NSString *URLString = [hrefRegex replacementStringForResult:result inString:tagAttributes offset:0 template:@"$1"];
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
                [linkAttributedString addAttribute:NSLinkAttributeName value:linkURL range:NSMakeRange(0, linkAttributedString.length)];
            }
            if (linkAttributedString) {
                [attributedString appendAttributedString:linkAttributedString];
            }
            linkString = nil;
            linkURL = nil;
        }
        location = range.location + range.length;
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
