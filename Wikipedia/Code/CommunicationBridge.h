//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
@import WebKit;

typedef void (^ JSListener)(NSString*, NSDictionary*);

@interface CommunicationBridge : NSObject <WKNavigationDelegate>

- (CommunicationBridge*)initWithWebView:(WKWebView*)targetWebView;

// This method calls the "loadHTML:withAssetsFile:" category method on
// UIWebView.
- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName;

WMF_TECH_DEBT_TODO(add error handling for HTML loading)

@end
