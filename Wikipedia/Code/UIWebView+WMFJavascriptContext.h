//  Created by Monte Hurd on 8/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
@import JavaScriptCore;
@import WebKit;

NS_ASSUME_NONNULL_BEGIN

@class JSContext;
@interface WKWebView (WMFJavascriptContext)

/**
 *  Retrieve the receiver's Javascript context.
 *
 *  Will raise an assertion if the context is @c nil.
 *
 *  @return The context, if one was found.
 */
- (nullable JSContext*)wmf_javascriptContext;

/**
 *  Retrieve an object from the global scope which should not be undefined.
 *
 *  Use this to retrieve things like object "namespaces" on which you can call <code>invokeMethod:withArguments:</code>
 *
 *  @return The value for the given key. Will raise an assertion if @c nil and the webview is done loading.
 */
- (nullable JSValue*)wmf_strictValueForKey:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
