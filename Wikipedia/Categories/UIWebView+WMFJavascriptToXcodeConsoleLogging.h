//  Created by Monte Hurd on 8/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIWebView (WMFJavascriptToXcodeConsoleLogging)

/**
 *  Adds 'xcodelog()' to 'window' obj for easy way to send debug
 *  messages from javascript land to the Xcode console.
 *  Example -
 *      In a js file we can do this:
 *          window.xcodelog('some debug string');
 */
- (void)wmf_enableJavascriptToXcodeConsoleLogging;

@end
