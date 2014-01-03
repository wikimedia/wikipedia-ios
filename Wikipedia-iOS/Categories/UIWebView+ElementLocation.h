//  Created by Monte Hurd on 12/28/13.
//  Html page shown by webview must reference elementLocation.js for these methods to work.

#import <UIKit/UIKit.h>

@interface UIWebView (ElementLocation)

- (CGRect)getScreenRectForHtmlElementWithId:(NSString *)elementId;
- (CGRect)getWebViewRectForHtmlElementWithId:(NSString *)elementId;

- (CGPoint)getScreenCoordsForHtmlImageWithSrc:(NSString *)src;
- (CGPoint)getWebViewCoordsForHtmlImageWithSrc:(NSString *)src;

@end
