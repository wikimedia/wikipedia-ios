@import WebKit;

@interface WKWebView (WMFWebViewControllerJavascript)

- (void)wmf_setTextSize:(NSInteger)textSize;

- (void)wmf_accessibilityCursorToFragment:(NSString *)fragment;

- (void)wmf_highlightLinkID:(NSString *)linkID;

- (void)wmf_unHighlightAllLinkIDs;

/**
 * Currently-selected text in the webview, if there is any.
 * @return The selection if it's longer than `kMinimumTextSelectionLength`, otherwise an empty string.
 */
- (void)wmf_getSelectedText:(void (^)(NSString *text))completion;

@end
