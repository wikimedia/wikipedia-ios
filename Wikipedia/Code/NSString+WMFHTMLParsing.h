@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface NSString (WMFHTMLParsing)
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
 * DEPRECATION WARNING: Utilize byAttributingString in String+HTML.swift for all new HTML --> NSAttributedString conversions. Only use this if absolutely necessary from Objective-C.
 */
- (NSMutableAttributedString *)wmf_attributedStringFromHTMLWithFont:(UIFont *)font
                                                           boldFont:(nullable UIFont *)boldFont
                                                         italicFont:(nullable UIFont *)italicFont
                                                     boldItalicFont:(nullable UIFont *)boldItalicFont
                                                              color:(nullable UIColor *)color
                                                          linkColor:(nullable UIColor *)color
                                                      handlingLinks:(BOOL)handlingLinks
                                                      handlingLists:(BOOL)handlingLists
                                            handlingSuperSubscripts:(BOOL)handlingSuperSubscripts
                                                         tagMapping:(nullable NSDictionary<NSString *, NSString *> *)tagMapping
                                            additionalTagAttributes:(nullable NSDictionary<NSString *, NSDictionary<NSAttributedStringKey, id> *> *)additionalTagAttributes;

@end

NS_ASSUME_NONNULL_END
