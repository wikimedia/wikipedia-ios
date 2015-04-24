//  Created by Monte Hurd on 11/21/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultAttributedString.h"
#import "Defines.h"
#import "NSString+Extras.h"
#import "UIColor+WMFHexColor.h"

static CGFloat const kFontSize    = 16.0f;
static NSInteger const kFontColor = 0x383838;

static CGFloat const kDescriptionFontSize    = 12.0f;
static NSInteger const kDescriptionFontColor = 0x606060;

static CGFloat const kSnippetFontSize         = 12.0f;
static NSInteger const kSnippetFontColor      = 0x000000;
static NSInteger const kSnippetHighlightColor = 0x0000ff;

static CGFloat const kHighlightedFontSize    = 16.0f;
static NSInteger const kHighlightedFontColor = 0x000000;

static CGFloat const kPaddingAboveDescription = 2.0f;
static CGFloat const kPaddingAboveSnippet     = 3.0f;

@implementation SearchResultAttributedString

+ (instancetype)initWithTitle:(NSString*)title
                      snippet:(NSString*)snippet
          wikiDataDescription:(NSString*)description
               highlightWords:(NSArray*)wordsToHighlight
         shouldHighlightWords:(BOOL)shouldHighlightWords
                   searchType:(SearchType)searchType {
    if (title.length == 0) {
        title = @"";
    }

    SearchResultAttributedString* outputString =
        (SearchResultAttributedString*)[[NSMutableAttributedString alloc] initWithString:title
                                                                              attributes:self.attributesTitle];

    if (shouldHighlightWords) {
        switch (searchType) {
            case SEARCH_TYPE_TITLES:
                for (NSString* word in wordsToHighlight.copy) {
                    // Highlight matches in title.
                    NSRange rangeOfWord =
                        [title rangeOfString:word
                                     options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch)];
                    [outputString setAttributes:self.attributesHighlight
                                          range:rangeOfWord];
                }
                break;
            case SEARCH_TYPE_IN_ARTICLES:
                [outputString setAttributes:self.attributesHighlight
                                      range:NSMakeRange(0, outputString.length)];
                break;
            default:
                break;
        }
    }

    // Append/style Wikidata description.
    if ((description.length > 0)) {
        NSAttributedString* attributedDesc =
            [[NSAttributedString alloc] initWithString:[@"\n" stringByAppendingString:description]
                                            attributes:self.attributesDescription];
        [outputString appendAttributedString:attributedDesc];
    }

    // Append/style the snippet, highlighting matches.
    if (snippet.length > 0) {
        NSMutableAttributedString* attrSnippet =
            [[NSMutableAttributedString alloc] initWithString:[@"\n" stringByAppendingString:snippet]
                                                   attributes:self.attributesSnippet];
        // Highlight words, but only on regex word boundary matches.
        NSError* error;
        for (NSString* word in wordsToHighlight.copy) {
            NSString* pattern = [NSString stringWithFormat:@"\\b(?:%@)\\b", [NSRegularExpression escapedPatternForString:word]];
            error = nil;
            NSRegularExpression* regex =
                [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:&error];
            if (!error) {
                [regex enumerateMatchesInString:[attrSnippet string] options:0
                                          range:NSMakeRange(0, attrSnippet.string.length)
                                     usingBlock:^(NSTextCheckingResult* match, NSMatchingFlags flags, BOOL* stop){
                    [attrSnippet setAttributes:self.attributesSnippetHighlight
                                         range:match.range];
                }];
            }
        }
        [outputString appendAttributedString:attrSnippet];
    }
    return outputString;
}

+ (NSDictionary*)attributesDescription {
    static NSDictionary* attributes = nil;
    if (!attributes) {
        NSMutableParagraphStyle* descriptionParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        descriptionParagraphStyle.paragraphSpacingBefore = kPaddingAboveDescription;
        attributes                                       =
            @{
            NSFontAttributeName: [UIFont systemFontOfSize:(kDescriptionFontSize * MENUS_SCALE_MULTIPLIER)],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kDescriptionFontColor alpha:1.0f],
            NSParagraphStyleAttributeName: descriptionParagraphStyle
        };
    }
    return attributes;
}

+ (NSDictionary*)attributesTitle {
    static NSDictionary* attributes = nil;
    if (!attributes) {
        attributes =
            @{
            NSFontAttributeName: [UIFont systemFontOfSize:(kFontSize * MENUS_SCALE_MULTIPLIER)],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kFontColor alpha:1.0f]
        };
    }
    return attributes;
}

+ (NSDictionary*)attributesSnippet {
    static NSDictionary* attributes = nil;
    if (!attributes) {
        NSMutableParagraphStyle* snippetParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        snippetParagraphStyle.paragraphSpacingBefore = kPaddingAboveSnippet;
        attributes                                   =
            @{
            NSParagraphStyleAttributeName: snippetParagraphStyle,
            NSFontAttributeName: [UIFont italicSystemFontOfSize:(kSnippetFontSize * MENUS_SCALE_MULTIPLIER)],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kSnippetFontColor alpha:1.0f]
        };
    }
    return attributes;
}

+ (NSDictionary*)attributesSnippetHighlight {
    static NSDictionary* attributes = nil;
    if (!attributes) {
        NSMutableParagraphStyle* snippetParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        snippetParagraphStyle.paragraphSpacingBefore = kPaddingAboveSnippet;
        attributes                                   =
            @{
            NSParagraphStyleAttributeName: snippetParagraphStyle,
            NSFontAttributeName: [UIFont italicSystemFontOfSize:(kSnippetFontSize * MENUS_SCALE_MULTIPLIER)],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kSnippetHighlightColor alpha:1.0f]
        };
    }
    return attributes;
}

+ (NSDictionary*)attributesHighlight {
    static NSDictionary* attributes = nil;
    if (!attributes) {
        attributes =
            @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:(kHighlightedFontSize * MENUS_SCALE_MULTIPLIER)],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kHighlightedFontColor alpha:1.0f]
        };
    }
    return attributes;
}

@end
