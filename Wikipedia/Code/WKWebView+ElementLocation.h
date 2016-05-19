//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

//  Html page shown by webview must reference elementLocation.js for these methods to work.

@import WebKit;

@interface WKWebView (ElementLocation)

- (void)getScreenRectForHtmlElementWithId:(NSString*)elementId completion:(void (^)(CGRect rect))completion;
- (void)getScrollViewRectForHtmlElementWithId:(NSString*)elementId completion:(void (^)(CGRect rect))completion;

- (void)getScreenRectForHtmlImageWithSrc:(NSString*)src completion:(void (^)(CGRect rect))completion;
- (void)getScrollViewRectForHtmlImageWithSrc:(NSString*)src completion:(void (^)(CGRect rect))completion;

/**
 *  Checks all html elements in the web view which have id's of format prefix string followed
 *  by count index (if prefix is "things_" and count is 3 it will check "thing_0", "thing_1"
 *  and "thing_2") to see if they are onscreen. Completion block is passed index of first one found to be so.
 */
- (void)getIndexOfTopOnScreenElementWithPrefix:(NSString*)prefix count:(NSUInteger)count completion:(void (^)(id index, NSError* error))completion;

@end
