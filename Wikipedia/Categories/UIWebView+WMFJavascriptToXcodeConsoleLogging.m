//  Created by Monte Hurd on 8/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@import JavaScriptCore;
#import "UIWebView+WMFJavascriptToXcodeConsoleLogging.h"
#import "UIWebView+WMFJavascriptContext.h"

@implementation UIWebView (WMFJavascriptToXcodeConsoleLogging)

- (void)wmf_enableJavascriptToXcodeConsoleLogging {
    [self wmf_javascriptContext][@"window"][@"xcodelog"] = ^(NSString* stringToLog) {
        NSLog(@"%@", stringToLog);
    };
}

@end
