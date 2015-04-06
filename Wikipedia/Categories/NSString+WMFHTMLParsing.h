#import <Foundation/Foundation.h>

@interface NSString (WMFHTMLParsing)

/// Parse the receiver as HTML and return the content of any text nodes found.
- (NSArray*)wmf_htmlTextNodes;

/**
 * Parse the receiver as HTML and return text node content joined by a space.
 * @discussion
 *
 * For example, given <code>"\<p\>Some string \<b\>with a bold substring\</b\>\</p\>"</code>,
 * this method would return <code>"Some string with a bold substring"</code>.
 *
 * @see wmf_htmlTextNodes
 */
- (NSString*)wmf_joinedHtmlTextNodes;

/**
 * Parse the receiver as HTML and return concatenated text node content, separated by @c delimiter.
 * @see wmf_htmlTextNodes
 */
- (NSString*)wmf_joinedHtmlTextNodesWithDelimiter:(NSString*)delimiter;

/**
 * Parse the receiver as HTML and return a heuristically defined snippet.
 */
- (NSString*)wmf_getStringSnippetWithoutHTML;

/**
 *
 *
 *  @return Return string with internal whitespace segments reduced to single space. Accounts for end of sentence punctuation like commas, semicolons and periods. Trims leading and trailing whitespace as well.
 */
- (NSString*)wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation;

- (NSString*)wmf_stringByCollapsingConsecutiveNewlines;
- (NSString*)wmf_stringByRecursivelyRemovingParenthesizedContent;
- (NSString*)wmf_stringByRemovingBracketedContent;
- (NSString*)wmf_stringByRemovingWhiteSpaceBeforeCommasAndSemicolons;
- (NSString*)wmf_stringByRemovingWhiteSpaceBeforePeriod;
- (NSString*)wmf_stringByCollapsingConsecutiveSpaces;
- (NSString*)wmf_stringByRemovingLeadingOrTrailingSpacesNewlinesOrColons;
- (NSString*)wmf_stringByCollapsingAllWhitespaceToSingleSpaces;

@end
