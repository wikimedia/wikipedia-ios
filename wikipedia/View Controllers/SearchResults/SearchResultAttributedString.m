//  Created by Monte Hurd on 11/21/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultAttributedString.h"
#import "Defines.h"
#import "NSString+Extras.h"

@implementation SearchResultAttributedString

+(instancetype)initWithTitle: (NSString *)title
                     snippet: (NSString *)snippet
         wikiDataDescription: (NSString *)description
              highlightWords: (NSArray *)wordsToHighlight
                  searchType: (SearchType)searchType
             attributesTitle: (NSDictionary *)attributesTitle
       attributesDescription: (NSDictionary *)attributesDescription
         attributesHighlight: (NSDictionary *)attributesHighlight
           attributesSnippet: (NSDictionary *)attributesSnippet
  attributesSnippetHighlight: (NSDictionary *)attributesSnippetHighlight
{
    if (title.length == 0) title = @"";
    SearchResultAttributedString *outputString =
    (SearchResultAttributedString *)[[NSMutableAttributedString alloc] initWithString: title
                                                                           attributes: attributesTitle];
    switch (searchType) {
        case SEARCH_TYPE_TITLES:
            for (NSString *word in wordsToHighlight.copy) {
                // Highlight matches in title.
                NSRange rangeOfWord =
                [title rangeOfString: word
                             options: (NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch)];
                [outputString setAttributes: attributesHighlight
                                      range: rangeOfWord];
            }
            break;
        case SEARCH_TYPE_IN_ARTICLES:
            [outputString setAttributes: attributesHighlight
                                  range: NSMakeRange(0, outputString.length)];
            break;
        default:
            break;
    }
    
    // Append/style Wikidata description.
    if ((description.length > 0)) {
        NSAttributedString *attributedDesc =
        [[NSAttributedString alloc] initWithString: [@"\n" stringByAppendingString:[description capitalizeFirstLetter]]
                                        attributes: attributesDescription];
        [outputString appendAttributedString:attributedDesc];
    }
    
    // Append/style the snippet, highlighting matches.
    if (snippet.length > 0) {
        NSMutableAttributedString *attrSnippet =
        [[NSMutableAttributedString alloc] initWithString: [@"\n" stringByAppendingString:snippet]
                                               attributes: attributesSnippet];
        // Highlight words, but only on regex word boundary matches.
        NSError *error;
        for (NSString *word in wordsToHighlight.copy) {
            NSString *pattern = [NSString stringWithFormat:@"\\b(?:%@)\\b", [NSRegularExpression escapedPatternForString: word]];
            error = nil;
            NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern: pattern
                                                      options: NSRegularExpressionCaseInsensitive
                                                        error: &error];
            if (!error) {
                [regex enumerateMatchesInString: [attrSnippet string] options:0
                                          range: NSMakeRange(0, attrSnippet.string.length)
                                     usingBlock: ^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                                         [attrSnippet setAttributes: attributesSnippetHighlight
                                                              range: match.range];
                                     }];
            }
        }
        [outputString appendAttributedString:attrSnippet];
    }
    return outputString;
}

@end
