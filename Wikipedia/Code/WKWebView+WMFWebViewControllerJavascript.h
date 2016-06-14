
@import WebKit;

@class MWKArticle, MWLanguageInfo;

@interface WKWebView (WMFWebViewControllerJavascript)

- (void)wmf_setTextSize:(NSInteger)textSize;

- (void)wmf_collapseTablesForArticle:(MWKArticle*)article;

- (void)wmf_setLanguage:(MWLanguageInfo*)languageInfo;

- (void)wmf_setPageProtected;

- (void)wmf_setBottomPadding:(NSInteger)bottomPadding;

- (void)wmf_scrollToFragment:(NSString*)fragment;

- (void)wmf_accessibilityCursorToFragment:(NSString*)fragment;

- (void)wmf_highlightLinkID:(NSString*)linkID;

- (void)wmf_unHighlightLinkID:(NSString*)linkID;

/**
 * Currently-selected text in the webview, if there is any.
 * @return The selection if it's longer than `kMinimumTextSelectionLength`, otherwise an empty string.
 */
- (void)wmf_getSelectedText:(void (^)(NSString* text))completion;

@end
