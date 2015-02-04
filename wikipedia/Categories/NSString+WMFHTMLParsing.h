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

@end
