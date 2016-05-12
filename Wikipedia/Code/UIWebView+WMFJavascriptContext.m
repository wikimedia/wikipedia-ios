//  Created by Monte Hurd on 8/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+WMFJavascriptContext.h"

static NSString* const WMFWebViewJavascriptContextPath = @"documentView.webView.mainFrame.javaScriptContext";

@implementation WKWebView (WMFJavascriptContext)

- (JSContext*)wmf_javascriptContext {
    JSContext* context = [self valueForKeyPath:WMFWebViewJavascriptContextPath];
    NSAssert([context isKindOfClass:[JSContext class]], @"No javascript context found for webView!");
    return context;
}

- (nullable JSValue*)wmf_strictValueForKey:(NSString*)key {
    NSParameterAssert(key.length);
    JSValue* definedValue = self.wmf_javascriptContext.globalObject[key];
    if (!definedValue || definedValue.isUndefined) {
        NSAssert(self.loading, @"Unexpected failure to find %@ in %@.", key, self);
        DDLogWarn(@"Couldn't find %@ in webview %@. Load state: %@",
                  key,
                  self,
                  self.loading ? @"Loading" : @"Loaded");
        return nil;
    }
    return definedValue;
}

@end
