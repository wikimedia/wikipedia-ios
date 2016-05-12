//  Created by Monte Hurd on 8/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@import WebKit;

@interface WKWebView (WMFJavascriptToXcodeConsoleLogging)

/**
 *  Adds 'console.log()' to global javascript namespace for sending
 *  debug messages from javascript land to the Xcode console.
 */
- (void)wmf_enableJavascriptToXcodeConsoleLogging;

@end
