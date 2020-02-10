@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface NSString (WMFHTMLParsing)

/// Parse the receiver as HTML and return the content of any text nodes found.
- (NSArray *)wmf_htmlTextNodes;

/**
 * Parse the receiver as HTML and return text node content joined by a space.
 * @discussion
 * For example, given <code>"\<p\>Some string \<b\>with a bold substring\</b\>\</p\>"</code>,
 * this method would return <code>"Some string with a bold substring"</code>.
 *
 * @see wmf_htmlTextNodes
 */
- (NSString *)wmf_joinedHtmlTextNodes;

/**
 * Parse the receiver as HTML and return concatenated text node content, separated by @c delimiter.
 * @see wmf_htmlTextNodes
 */
- (NSString *)wmf_joinedHtmlTextNodesWithDelimiter:(NSString *)delimiter;

/**
 * String sanitation method to remove wiki markup & other text artifacts prior to sharing.
 * @return A new string with sanitation processing applied.
 */
- (NSString *)wmf_shareSnippetFromText;

/**
 *  @return Return string with internal whitespace segments reduced to single space. Accounts for end of sentence punctuation like commas, semicolons and periods. Trims leading and trailing whitespace as well.
 */
- (NSString *)wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation;

- (NSString *)wmf_stringByCollapsingConsecutiveNewlines;
- (NSString *)wmf_stringByRecursivelyRemovingParenthesizedContent;
- (NSString *)wmf_stringByRemovingBracketedContent;
- (NSString *)wmf_stringByRemovingWhiteSpaceBeforePeriodsCommasSemicolonsAndDashes;
- (NSString *)wmf_stringByCollapsingConsecutiveSpaces;
- (NSString *)wmf_stringByRemovingLeadingOrTrailingSpacesNewlinesOrColons;
- (NSString *)wmf_stringByCollapsingAllWhitespaceToSingleSpaces;

- (NSString *)wmf_summaryFromText;

- (void)wmf_enumerateHTMLImageTagContentsWithHandler:(nonnull void (^)(NSString *imageTagContents, NSRange range))handler;

- (nonnull NSString *)wmf_stringByRemovingHTML;

/**
 *  Converts HTML string with <i></i> and <b></b> tags to NSAttributedString with the specified italic and bold fonts. Optionally bolds an additional string based on matching.
 *  Please don't remove this and convert to alloc/init'ing the attributed string with @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType}
 *  It's slower and was the source of crashes in the past. https://developer.apple.com/documentation/foundation/nsattributedstring/1524613-initwithdata
 */

/**
 *  Converts HTML string with <i></i> and <b></b> tags to NSAttributedString with the specified italic and bold fonts. Optionally bolds an additional string based on matching.
 *  @discussion Please don't remove this and convert to alloc/init'ing the attributed string with @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} It's slower and was the source of crashes in the past. https://developer.apple.com/documentation/foundation/nsattributedstring/1524613-initwithdata
 *
 * @param font           Base font for the returned attributed string
 * @param boldFont       Bold font for the returned attribued string
 * @param italicFont     Italic font for the returned attributed string
 * @param boldItalicFont Bold & italic font for the returned attributed string
 * @param color Text color
 * @param linkColor Link color
 * @param linkBaseURL Base URL for parsed links
 * @param handlingLists Whether or not list tags should be parsed
 * @param handlingSuperSubscripts whether or not super and subscript should be parsed
 * @param withAdditionalBoldingForMatchingSubstring   String to match for additional bolding
 * @param tagMapping     Lowercase string tag name to another lowercase string tag name - converts tags, for example, @{@"a":@"b"} will turn <a></a> tags to <b></b> tags
 * @param additionalTagAttributes Additional text attributes for given tags - lowercase tag name to attribute key/value pairs
 * @return attributed string
 */
- (NSMutableAttributedString *)wmf_attributedStringFromHTMLWithFont:(UIFont *)font
                                                           boldFont:(nullable UIFont *)boldFont
                                                         italicFont:(nullable UIFont *)italicFont
                                                     boldItalicFont:(nullable UIFont *)boldItalicFont
                                                              color:(nullable UIColor *)color
                                                          linkColor:(nullable UIColor *)color
                                                      handlingLists:(BOOL)handlingLists
                                            handlingSuperSubscripts:(BOOL)handlingSuperSubscripts
                          withAdditionalBoldingForMatchingSubstring:(nullable NSString *)stringToBold
                                                         tagMapping:(nullable NSDictionary<NSString *, NSString *> *)tagMapping
                                            additionalTagAttributes:(nullable NSDictionary<NSString *, NSDictionary<NSAttributedStringKey, id> *> *)additionalTagAttributes;

/*
 * Convienence method for the method above.
 */
- (NSMutableAttributedString *)wmf_attributedStringFromHTMLWithFont:(UIFont *)font boldFont:(nullable UIFont *)boldFont italicFont:(nullable UIFont *)italicFont boldItalicFont:(nullable UIFont *)boldItalicFont color:(nullable UIColor *)color linkColor:(nullable UIColor *)linkColor handlingLists:(BOOL)handlingLists handlingSuperSubscripts:(BOOL)handlingSuperSubscripts withAdditionalBoldingForMatchingSubstring:(nullable NSString *)stringToBold;

@end

NS_ASSUME_NONNULL_END
