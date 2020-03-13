@import WebKit;

@interface WKWebView (ElementLocation)

/// Use PCS methods instead where available
- (void)getScreenRectForHtmlElementWithId:(NSString *)elementId completion:(void (^)(CGRect rect))completion;

/// Use PCS methods instead where available
- (void)getScrollViewRectForHtmlElementWithId:(NSString *)elementId completion:(void (^)(CGRect rect))completion;

@end
