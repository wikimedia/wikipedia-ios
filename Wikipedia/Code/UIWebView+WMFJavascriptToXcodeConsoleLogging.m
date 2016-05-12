//  Created by Monte Hurd on 8/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@import JavaScriptCore;
#import "UIWebView+WMFJavascriptToXcodeConsoleLogging.h"
#import "UIWebView+WMFJavascriptContext.h"

@implementation WKWebView (WMFJavascriptToXcodeConsoleLogging)

- (void)wmf_enableJavascriptToXcodeConsoleLogging {
#if DEBUG
    JSValue* console = [[self wmf_javascriptContext] globalObject][@"console"];
    @weakify(self);
    console[@"log"] = ^(NSString* message) {
        @strongify(self);
        [self logWebViewMessage:message];
    };
#endif
}

- (void)logWebViewMessage:(NSString*)message {
    NSLog(@"%@", message);
}

@end
