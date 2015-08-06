//  Created by Monte Hurd on 8/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class JSContext;
@interface UIWebView (WMFJavascriptContext)

- (JSContext*)wmf_javascriptContext;

- (NSArray*)wmf_getArrayFromJavascriptFunctionNamed:(NSString*)name withArguments:(NSArray*)arguments;

@end
