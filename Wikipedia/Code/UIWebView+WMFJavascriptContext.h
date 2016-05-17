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

@end

NS_ASSUME_NONNULL_END
