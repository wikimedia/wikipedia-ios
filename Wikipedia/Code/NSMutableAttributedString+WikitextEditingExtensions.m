#import "NSMutableAttributedString+WikitextEditingExtensions.h"
#import "Wikipedia-Swift.h"

@implementation NSMutableAttributedString (WikitextEditingExtensions)

-(void)addWikitextSyntaxFormattingWithSearchRange: (NSRange)searchRange fontSizeTraitCollection: (UITraitCollection *)fontSizeTraitCollection needsColors: (BOOL)needsColors theme: (WMFTheme *)theme {

    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    UIFontDescriptor *boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFontDescriptor *italicFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    UIFontDescriptor *boldItalicFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold];
    UIFont *standardFont = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:16]];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:standardFont.pointSize];
    UIFont *italicFont = [UIFont fontWithDescriptor:italicFontDescriptor size:standardFont.pointSize];
    UIFont *boldItalicFont = [UIFont fontWithDescriptor:boldItalicFontDescriptor size:standardFont.pointSize];

    UIFont *h2Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:26]];
    UIFont *h3Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:24]];
    UIFont *h4Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:22]];
    UIFont *h5Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:20]];
    UIFont *h6Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:18]];
    // UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont.systemFont(ofSize: size, weight: weight))

    NSString *boldItalicRegexStr = @"('{5})([^']*(?:'(?!'''')[^']*)*)('{5})";
    NSString *boldRegexStr = @"('{3})([^']*(?:'(?!'')[^']*)*)('{3})";

    // Explaining the most complicated example here, others (bold, italic, link) follow a similar pattern
    // ('{2})       - matches opening ''. Captures in group so it can be orangified.
    // (            - start of capturing group. The group that will be italisized.
    // [^']*        - matches any character that isn't a ' zero or more times
    // (?:          - beginning of non-capturing group
    // (?<!')'(?!') - matches any ' that are NOT followed or preceded by another ' (so single apostrophes or words like "don't" still get formatted
    // [^']*        - matches any character that isn't a ' zero or more times
    // )*           - end of non-capturing group, which can happen zero or more times (i.e. all single apostrophe logic)
    // )            - end of capturing group. End italisization
    // ('{2})       - matches ending ''. Captures in group so it can be orangified.

    NSString *italicRegexStr = @"('{2})([^']*(?:(?<!')'(?!')[^']*)*)('{2})";
    NSString *linkRegexStr = @"(\\[{2})[^\\[]*(?:\\[(?!\\[)[^'\\[]*)*(\\]{2})";
    NSString *templateRegexStr = @"\\{{2}[^\\}]*\\}{2}";

    NSString *refRegexStr = @"(<ref>)\\s*.*?(<\\/ref>)";
    NSString *refWithAttributesRegexStr = @"(<ref\\s+.+?>)\\s*.*?(<\\/ref>)";
    NSString *refSelfClosingRegexStr = @"<ref\\s[^>]+?\\s*\\/>";
    
    NSString *supRegexStr = @"(<sup>)\\s*.*?(<\\/sup>)";
    NSString *subRegexStr = @"(<sub>)\\s*.*?(<\\/sub>)";
    NSString *underlineRegexStr = @"(<u>)\\s*.*?(<\\/u>)";
    NSString *strikethroughRegexStr = @"(<s>)\\s*.*?(<\\/s>)";
    
    NSString *h2RegexStr = @"(={2})([^=]*)(={2})(?!=)"; // todo: why is beginning carat ^ flaky
    NSString *h3RegexStr = @"(={3})([^=]*)(={3})(?!=)"; // todo: why is beginning carat ^ flaky
    NSString *h4RegexStr = @"(={4})([^=]*)(={4})(?!=)"; // todo: why is beginning carat ^ flaky
    NSString *h5RegexStr = @"(={5})([^=]*)(={5})(?!=)"; // todo: why is beginning carat ^ flaky
    NSString *h6RegexStr = @"(={6})([^=]*)(={6})(?!=)"; // todo: why is beginning carat ^ flaky

    NSString *bulletPointRegexStr = @"^(\\*+)(.*)";
    NSString *listNumberRegexStr = @"^(#+)(.*)";

    NSRegularExpression *boldItalicRegex = [NSRegularExpression regularExpressionWithPattern:boldItalicRegexStr options:0 error:nil];
    NSRegularExpression *boldRegex = [NSRegularExpression regularExpressionWithPattern:boldRegexStr options:0 error:nil];
    NSRegularExpression *italicRegex = [NSRegularExpression regularExpressionWithPattern:italicRegexStr options:0 error:nil];
    NSRegularExpression *linkRegex = [NSRegularExpression regularExpressionWithPattern:linkRegexStr options:0 error:nil];
    NSRegularExpression *templateRegex = [NSRegularExpression regularExpressionWithPattern:templateRegexStr options:0 error:nil];
    NSRegularExpression *refRegex = [NSRegularExpression regularExpressionWithPattern:refRegexStr options:0 error:nil];
    NSRegularExpression *refWithAttributesRegex = [NSRegularExpression regularExpressionWithPattern:refWithAttributesRegexStr options:0 error:nil];
    NSRegularExpression *refSelfClosingRegex = [NSRegularExpression regularExpressionWithPattern:refSelfClosingRegexStr options:0 error:nil];
    NSRegularExpression *supRegex = [NSRegularExpression regularExpressionWithPattern:supRegexStr options:0 error:nil];
    NSRegularExpression *subRegex = [NSRegularExpression regularExpressionWithPattern:subRegexStr options:0 error:nil];
    
    NSRegularExpression *underlineRegex = [NSRegularExpression regularExpressionWithPattern:underlineRegexStr options:0 error:nil];
    NSRegularExpression *strikethroughRegex = [NSRegularExpression regularExpressionWithPattern:strikethroughRegexStr options:0 error:nil];
    
    NSRegularExpression *h2Regex = [NSRegularExpression regularExpressionWithPattern:h2RegexStr options:0 error:nil];
    NSRegularExpression *h3Regex = [NSRegularExpression regularExpressionWithPattern:h3RegexStr options:0 error:nil];
    NSRegularExpression *h4Regex = [NSRegularExpression regularExpressionWithPattern:h4RegexStr options:0 error:nil];
    NSRegularExpression *h5Regex = [NSRegularExpression regularExpressionWithPattern:h5RegexStr options:0 error:nil];
    NSRegularExpression *h6Regex = [NSRegularExpression regularExpressionWithPattern:h6RegexStr options:0 error:nil];
    NSRegularExpression *bulletPointRegex = [NSRegularExpression regularExpressionWithPattern:bulletPointRegexStr options:0 error:nil];
    NSRegularExpression *listNumberRegex = [NSRegularExpression regularExpressionWithPattern:listNumberRegexStr options:0 error:nil];

    NSDictionary *boldAttributes = @{
        NSFontAttributeName: boldFont,
    };

    NSDictionary *italicAttributes = @{
        NSFontAttributeName: italicFont,
    };

    NSDictionary *boldItalicAttributes = @{
        NSFontAttributeName: boldItalicFont,
    };

    NSDictionary *linkAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorLink
    };

    NSDictionary *templateAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorTemplate
    };

    NSDictionary *htmlTagAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorHtmlTag
    };

    NSDictionary *orangeFontAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorShorthand
    };

    NSDictionary *h2FontAttributes = @{
        NSFontAttributeName: h2Font,
    };
    
    NSDictionary *h3FontAttributes = @{
        NSFontAttributeName: h3Font,
    };
    
    NSDictionary *h4FontAttributes = @{
        NSFontAttributeName: h4Font,
    };
    
    NSDictionary *h5FontAttributes = @{
        NSFontAttributeName: h5Font,
    };

    NSDictionary *h6FontAttributes = @{
        NSFontAttributeName: h6Font,
    };
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:5];
    [paragraphStyle setLineHeightMultiple:1.1];

    NSDictionary *commonAttributes = @{
        NSFontAttributeName: standardFont,
        NSParagraphStyleAttributeName: paragraphStyle,
        NSForegroundColorAttributeName: theme.colors.primaryText
    };

    NSDictionary *wikitextBoldAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper boldKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextItalicAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper italicKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextBoldAndItalicAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper boldAndItalicKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextLinkAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper linkKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextTemplateAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper templateKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextRefAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper refKey]: [NSNumber numberWithBool:YES]
    };
    
    NSDictionary *wikitextSupAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper superscriptKey]: [NSNumber numberWithBool:YES]
    };
    
    NSDictionary *wikitextSubAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper subscriptKey]: [NSNumber numberWithBool:YES]
    };
    
    NSDictionary *wikitextUnderlineAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper underlineKey]: [NSNumber numberWithBool:YES]
    };
    
    NSDictionary *wikitextStrikethroughAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper strikethroughKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextRefWithAttributesAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper refWithAttributesKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextRefSelfClosingAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper refSelfClosingKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextH2Attributes = @{
        [WMFWikitextAttributedStringKeyWrapper h2Key]: [NSNumber numberWithBool:YES]
    };
    
    NSDictionary *wikitextH3Attributes = @{
        [WMFWikitextAttributedStringKeyWrapper h3Key]: [NSNumber numberWithBool:YES]
    };
    
    NSDictionary *wikitextH4Attributes = @{
        [WMFWikitextAttributedStringKeyWrapper h4Key]: [NSNumber numberWithBool:YES]
    };
    
    NSDictionary *wikitextH5Attributes = @{
        [WMFWikitextAttributedStringKeyWrapper h5Key]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextH6Attributes = @{
        [WMFWikitextAttributedStringKeyWrapper h6Key]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextBulletAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper bulletKey]: [NSNumber numberWithBool:YES]
    };

    NSDictionary *wikitextListNumberAttributes = @{
        [WMFWikitextAttributedStringKeyWrapper listNumberKey]: [NSNumber numberWithBool:YES]
    };

    [self addAttributes:commonAttributes range:searchRange];

    [refRegex enumerateMatchesInString:self.string
                               options:0
                                 range:searchRange
                            usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                NSRange matchRange = [result rangeAtIndex:0];
                                NSRange openingRange = [result rangeAtIndex:1];
                                NSRange closingRange = [result rangeAtIndex:2];

                                if (matchRange.location != NSNotFound) {
                                    [self addAttributes:wikitextRefAttributes range:matchRange];
                                }

                                if (openingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:openingRange];
                                }

                                if (closingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:closingRange];
                                }
                            }];

    [refWithAttributesRegex enumerateMatchesInString:self.string
                                             options:0
                                               range:searchRange
                                          usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                              NSRange matchRange = [result rangeAtIndex:0];

                                              if (matchRange.location != NSNotFound) {
                                                  [self addAttributes:htmlTagAttributes range:matchRange];
                                                  [self addAttributes:wikitextRefWithAttributesAttributes range:matchRange];
                                              }
                                          }];

    [refSelfClosingRegex enumerateMatchesInString:self.string
                                          options:0
                                            range:searchRange
                                       usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                           NSRange matchRange = [result rangeAtIndex:0];

                                           if (matchRange.location != NSNotFound) {
                                               [self addAttributes:htmlTagAttributes range:matchRange];
                                               [self addAttributes:wikitextRefSelfClosingAttributes range:matchRange];
                                           }
                                       }];

    [templateRegex enumerateMatchesInString:self.string
                                    options:0
                                      range:searchRange
                                 usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                     NSRange matchRange = [result rangeAtIndex:0];

                                     if (matchRange.location != NSNotFound) {
                                         [self addAttributes:templateAttributes range:matchRange];
                                         [self addAttributes:wikitextTemplateAttributes range:matchRange];
                                     }
                                 }];
    
    [supRegex enumerateMatchesInString:self.string
                               options:0
                                 range:searchRange
                            usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                NSRange matchRange = [result rangeAtIndex:0];
                                NSRange openingRange = [result rangeAtIndex:1];
                                NSRange closingRange = [result rangeAtIndex:2];

                                if (matchRange.location != NSNotFound) {
                                    [self addAttributes:wikitextSupAttributes range:matchRange];
                                }

                                if (openingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:openingRange];
                                }

                                if (closingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:closingRange];
                                }
                            }];
    
    [subRegex enumerateMatchesInString:self.string
                               options:0
                                 range:searchRange
                            usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                NSRange matchRange = [result rangeAtIndex:0];
                                NSRange openingRange = [result rangeAtIndex:1];
                                NSRange closingRange = [result rangeAtIndex:2];

                                if (matchRange.location != NSNotFound) {
                                    [self addAttributes:wikitextSubAttributes range:matchRange];
                                }

                                if (openingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:openingRange];
                                }

                                if (closingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:closingRange];
                                }
                            }];
    
    [underlineRegex enumerateMatchesInString:self.string
                               options:0
                                 range:searchRange
                            usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                NSRange matchRange = [result rangeAtIndex:0];
                                NSRange openingRange = [result rangeAtIndex:1];
                                NSRange closingRange = [result rangeAtIndex:2];

                                if (matchRange.location != NSNotFound) {
                                    [self addAttributes:wikitextUnderlineAttributes range:matchRange];
                                }

                                if (openingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:openingRange];
                                }

                                if (closingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:closingRange];
                                }
                            }];
    
    [strikethroughRegex enumerateMatchesInString:self.string
                               options:0
                                 range:searchRange
                            usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                NSRange matchRange = [result rangeAtIndex:0];
                                NSRange openingRange = [result rangeAtIndex:1];
                                NSRange closingRange = [result rangeAtIndex:2];

                                if (matchRange.location != NSNotFound) {
                                    [self addAttributes:wikitextStrikethroughAttributes range:matchRange];
                                }

                                if (openingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:openingRange];
                                }

                                if (closingRange.location != NSNotFound) {
                                    [self addAttributes:htmlTagAttributes range:closingRange];
                                }
                            }];

    [italicRegex enumerateMatchesInString:self.string
                                  options:0
                                    range:searchRange
                               usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                   NSRange openingRange = [result rangeAtIndex:1];
                                   NSRange textRange = [result rangeAtIndex:2];
                                   NSRange closingRange = [result rangeAtIndex:3];

                                   if (textRange.location != NSNotFound) {
                                       [self addAttributes:italicAttributes range:textRange];
                                       [self addAttributes:wikitextItalicAttributes range:textRange];
                                   }

                                   if (openingRange.location != NSNotFound) {
                                       [self addAttributes:orangeFontAttributes range:openingRange];
                                   }

                                   if (closingRange.location != NSNotFound) {
                                       [self addAttributes:orangeFontAttributes range:closingRange];
                                   }
                               }];

    [boldRegex enumerateMatchesInString:self.string
                                options:0
                                  range:searchRange
                             usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                 NSRange fullMatch = [result rangeAtIndex:0];
                                 NSRange openingRange = [result rangeAtIndex:1];
                                 NSRange textRange = [result rangeAtIndex:2];
                                 NSRange closingRange = [result rangeAtIndex:3];

                                 if (textRange.location != NSNotFound) {

                                     // helps to undo attributes from bold and italic single regex above.
                                     [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper italicKey] range:fullMatch];

                                     [self addAttributes:boldAttributes range:textRange];
                                     [self addAttributes:wikitextBoldAttributes range:textRange];
                                 }

                                 if (openingRange.location != NSNotFound) {
                                     [self addAttributes:orangeFontAttributes range:openingRange];
                                 }

                                 if (closingRange.location != NSNotFound) {
                                     [self addAttributes:orangeFontAttributes range:closingRange];
                                 }
                             }];

    [boldItalicRegex enumerateMatchesInString:self.string
                                      options:0
                                        range:searchRange
                                   usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                       NSRange fullMatch = [result rangeAtIndex:0];
                                       NSRange openingRange = [result rangeAtIndex:1];
                                       NSRange textRange = [result rangeAtIndex:2];
                                       NSRange closingRange = [result rangeAtIndex:3];

                                       if (textRange.location != NSNotFound) {

                                           // helps to undo attributes from bold and italic single regex above.
                                           [self removeAttribute:NSFontAttributeName range:fullMatch];
                                           [self removeAttribute:NSForegroundColorAttributeName range:fullMatch];
                                           [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper boldKey] range:fullMatch];
                                           [self removeAttribute:[WMFWikitextAttributedStringKeyWrapper italicKey] range:fullMatch];
                                           [self addAttributes:commonAttributes range:fullMatch];

                                           [self addAttributes:boldItalicAttributes range:textRange];
                                           [self addAttributes:wikitextBoldAndItalicAttributes range:textRange];
                                       }

                                       if (openingRange.location != NSNotFound) {
                                           [self addAttributes:orangeFontAttributes range:openingRange];
                                       }

                                       if (closingRange.location != NSNotFound) {
                                           [self addAttributes:orangeFontAttributes range:closingRange];
                                       }
                                   }];

    [linkRegex enumerateMatchesInString:self.string
                                options:0
                                  range:searchRange
                             usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                 NSRange matchRange = [result rangeAtIndex:0];

                                 if (matchRange.location != NSNotFound) {
                                     [self addAttributes:linkAttributes range:matchRange];
                                     [self addAttributes:wikitextLinkAttributes range:matchRange];
                                 }
                             }];

    [h2Regex enumerateMatchesInString:self.string
                              options:0
                                range:searchRange
                           usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                               NSRange openingRange = [result rangeAtIndex:1];
                               NSRange textRange = [result rangeAtIndex:2];
                               NSRange closingRange = [result rangeAtIndex:3];

                               if (textRange.location != NSNotFound) {
                                   [self addAttributes:h2FontAttributes range:textRange];
                                   [self addAttributes:wikitextH2Attributes range:textRange];
                               }

                               if (openingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:openingRange];
                                   [self addAttributes:h2FontAttributes range:openingRange];
                               }

                               if (closingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:closingRange];
                                   [self addAttributes:h2FontAttributes range:closingRange];
                               }
                           }];
    
    [h3Regex enumerateMatchesInString:self.string
                              options:0
                                range:searchRange
                           usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                               NSRange openingRange = [result rangeAtIndex:1];
                               NSRange textRange = [result rangeAtIndex:2];
                               NSRange closingRange = [result rangeAtIndex:3];

                               if (textRange.location != NSNotFound) {
                                   [self addAttributes:h5FontAttributes range:textRange];
                                   [self addAttributes:wikitextH3Attributes range:textRange];
                               }

                               if (openingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:openingRange];
                                   [self addAttributes:h3FontAttributes range:openingRange];
                               }

                               if (closingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:closingRange];
                                   [self addAttributes:h3FontAttributes range:closingRange];
                               }
                           }];
    
    [h4Regex enumerateMatchesInString:self.string
                              options:0
                                range:searchRange
                           usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                               NSRange openingRange = [result rangeAtIndex:1];
                               NSRange textRange = [result rangeAtIndex:2];
                               NSRange closingRange = [result rangeAtIndex:3];

                               if (textRange.location != NSNotFound) {
                                   [self addAttributes:h5FontAttributes range:textRange];
                                   [self addAttributes:wikitextH4Attributes range:textRange];
                               }

                               if (openingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:openingRange];
                                   [self addAttributes:h4FontAttributes range:openingRange];
                               }

                               if (closingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:closingRange];
                                   [self addAttributes:h4FontAttributes range:closingRange];
                               }
                           }];
    
    [h5Regex enumerateMatchesInString:self.string
                              options:0
                                range:searchRange
                           usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                               NSRange openingRange = [result rangeAtIndex:1];
                               NSRange textRange = [result rangeAtIndex:2];
                               NSRange closingRange = [result rangeAtIndex:3];

                               if (textRange.location != NSNotFound) {
                                   [self addAttributes:h5FontAttributes range:textRange];
                                   [self addAttributes:wikitextH5Attributes range:textRange];
                               }

                               if (openingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:openingRange];
                                   [self addAttributes:h5FontAttributes range:openingRange];
                               }

                               if (closingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:closingRange];
                                   [self addAttributes:h5FontAttributes range:closingRange];
                               }
                           }];

    [h6Regex enumerateMatchesInString:self.string
                              options:0
                                range:searchRange
                           usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                               NSRange openingRange = [result rangeAtIndex:1];
                               NSRange textRange = [result rangeAtIndex:2];
                               NSRange closingRange = [result rangeAtIndex:3];

                               if (textRange.location != NSNotFound) {
                                   [self addAttributes:h6FontAttributes range:textRange];
                                   [self addAttributes:wikitextH6Attributes range:textRange];
                               }

                               if (openingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:openingRange];
                                   [self addAttributes:h6FontAttributes range:openingRange];
                               }

                               if (closingRange.location != NSNotFound) {
                                   [self addAttributes:orangeFontAttributes range:closingRange];
                                   [self addAttributes:h6FontAttributes range:closingRange];
                               }
                           }];

    [bulletPointRegex enumerateMatchesInString:self.string
                                       options:0
                                         range:searchRange
                                    usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                        NSRange allRange = [result rangeAtIndex:0];
                                        NSRange bulletRange = [result rangeAtIndex:1];

                                        if (bulletRange.location != NSNotFound) {
                                            [self addAttributes:orangeFontAttributes range:bulletRange];
                                        }

                                        if (allRange.location != NSNotFound) {
                                            [self addAttributes:wikitextBulletAttributes range:allRange];
                                        }
                                    }];
}

@end
