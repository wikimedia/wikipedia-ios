//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

//  Html page shown by webview must reference elementLocation.js for these methods to work.

@import WebKit;

@interface WKWebView (ElementLocation)

- (void)getScreenRectForHtmlElementWithId:(NSString*)elementId completion:(void (^)(CGRect rect))completion;
- (void)getWebViewRectForHtmlElementWithId:(NSString*)elementId completion:(void (^)(CGRect rect))completion;

//- (CGPoint)getScreenCoordsForHtmlImageWithSrc:(NSString*)src;
//- (CGPoint)getWebViewCoordsForHtmlImageWithSrc:(NSString*)src;

- (NSInteger)getIndexOfTopOnScreenElementWithPrefix:(NSString*)prefix count:(NSUInteger)count;

@end
