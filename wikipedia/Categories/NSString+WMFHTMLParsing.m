#import "NSString+WMFHTMLParsing.h"
#import "WikipediaAppUtils.h"
#import <hpple/TFHpple.h>

static const int kMinimumLengthForPreTransformedHTMLForSnippet = 40;
static const int kHighestIndexForSubstringAfterHTMLRemoved     = 350;

@implementation NSString (WMFHTMLParsing)

- (NSArray*)wmf_htmlTextNodes {
    return [[[[TFHpple alloc]
              initWithHTMLData:[self dataUsingEncoding:NSUTF8StringEncoding]]
             searchWithXPathQuery:@"//text()"]
            valueForKey:WMF_SAFE_KEYPATH([TFHppleElement new], content)];
}

- (NSString*)wmf_joinedHtmlTextNodes {
    return [self wmf_joinedHtmlTextNodesWithDelimiter:@" "];
}

- (NSString*)wmf_joinedHtmlTextNodesWithDelimiter:(NSString*)delimiter {
    return [[self wmf_htmlTextNodes] componentsJoinedByString:delimiter];
}

- (NSString*)wmf_getStringSnippetWithoutHTML {
    if (self.length < kMinimumLengthForPreTransformedHTMLForSnippet) {
        return nil;
    }
    NSData* stringData      = [self dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple* parser         = [TFHpple hppleWithHTMLData:stringData];
    NSArray* textNodes      = [parser searchWithXPathQuery:@"//p[1]//text()"];
    NSMutableArray* results = @[].mutableCopy;
    for (TFHppleElement* node in textNodes) {
        [results addObject:node.raw];
    }
    NSString* result = [results componentsJoinedByString:@""];
    result = [result substringToIndex:
              MIN(kHighestIndexForSubstringAfterHTMLRemoved, result.length)];
    result = [NSString wmf_stringSnippetSimplifiedInString:result];
    return result.length >= kMinimumLengthForPreTransformedHTMLForSnippet ?
           result : nil;
}

+ (NSString*)wmf_stringSnippetSimplifiedInString:(NSString*)string {
    NSString* result                   = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    NSError* err                       = nil;
    NSRegularExpression* newlinesRegex = [NSRegularExpression
                                          regularExpressionWithPattern:@"\n{2,}"
                                                               options:0
                                                                 error:&err];
    NSRange range = NSMakeRange(0, result.length);
    result = [newlinesRegex stringByReplacingMatchesInString:result
                                                     options:0
                                                       range:range
                                                withTemplate:@"\n"];


    // We probably don't want to try to handle ideographic parens
    err = nil;
    NSRegularExpression* parensRegex = [NSRegularExpression
                                        regularExpressionWithPattern:@"[(][^)]+[)]"
                                                             options:0
                                                               error:&err];
    range  = NSMakeRange(0, result.length);
    result = [parensRegex stringByReplacingMatchesInString:result
                                                   options:0
                                                     range:range
                                              withTemplate:@""];

    // Nor do we want to try to handle ideographic brackets
    err = nil;
    NSRegularExpression* bracketsRegex = [NSRegularExpression
                                          regularExpressionWithPattern:@"\\[[^]]+]"
                                                               options:0
                                                                 error:&err];
    range  = NSMakeRange(0, result.length);
    result = [bracketsRegex stringByReplacingMatchesInString:result
                                                     options:0
                                                       range:range
                                                withTemplate:@""];

    // Unlike parens and brackets and unlike doubled up space in general,
    // we do not want whitespace preceding the comma or ideographic comma
    err = nil;
    NSRegularExpression* whitespaceCommaRegex = [NSRegularExpression
                                                 regularExpressionWithPattern:@"\\s+([,、])"
                                                                      options:0
                                                                        error:&err];
    range  = NSMakeRange(0, result.length);
    result = [whitespaceCommaRegex stringByReplacingMatchesInString:result
                                                            options:0
                                                              range:range
                                                       withTemplate:@"$1"];

    // Ideographic stops from TextExtracts, which were from OpenSearch
    err = nil;
    NSRegularExpression* whitespacePeriodRegex = [NSRegularExpression
                                                  regularExpressionWithPattern:@"\\s+([\\.|。|．|｡])"
                                                                       options:0
                                                                         error:&err];
    range  = NSMakeRange(0, result.length);
    result = [whitespacePeriodRegex stringByReplacingMatchesInString:result
                                                             options:0
                                                               range:range
                                                        withTemplate:@"$1"];

    // In practice, we rarely care about doubled up whitespace in the
    // string except for the actual space character
    err = nil;
    NSRegularExpression* spacesRegex = [NSRegularExpression
                                        regularExpressionWithPattern:@" {2,}"
                                                             options:0
                                                               error:&err];
    range  = NSMakeRange(0, result.length);
    result = [spacesRegex stringByReplacingMatchesInString:result
                                                   options:0
                                                     range:range
                                              withTemplate:@" "];

    // Note about trailing colon characters: they usually look strange if kept,
    // and removing them (plus spaces and newlines) doesn't often create merged
    // words that look bad - these are usually at tag boundaries. For Latinized
    // langs sometimes this means words like "include" finish the snippet.
    // But as a matter of markup structure, something like a <p> tag
    // shouldn't be </p> closed until something like <ul>...</ul> is closed.
    // In fact, some sections have this layout, and some do not.
    err = nil;
    NSRegularExpression* leadingTrailingWhitespaceNewlineRegex = [NSRegularExpression
                                                                  regularExpressionWithPattern:@"^[\\s\n]+|[\\s\n:]+$"
                                                                                       options:0
                                                                                         error:&err];
    range  = NSMakeRange(0, result.length);
    result = [leadingTrailingWhitespaceNewlineRegex stringByReplacingMatchesInString:result
                                                                             options:0
                                                                               range:range
                                                                        withTemplate:@""];

    return result;
}

@end
