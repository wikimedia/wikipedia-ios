//  Created by Monte Hurd on 1/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PreviewWebView.h"
#import "SessionSingleton.h"
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface PreviewWebView ()

@end

@implementation PreviewWebView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor        = [UIColor whiteColor];
        self.navigationDelegate     = self;
        self.userInteractionEnabled = YES;
//        self.dataDetectorTypes = UIDataDetectorTypeNone;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews]; // get width from solved constraints

    [self forceScrollViewContentSizeToReflectActualHTMLHeight];
}

- (void)forceScrollViewContentSizeToReflectActualHTMLHeight {
    // Only run this if the width has changed. Otherwise it will recurse endlessly.
    static CGFloat lastWidth = 0;
    if (lastWidth == self.scrollView.frame.size.width) {
        return;
    }
    lastWidth = self.scrollView.frame.size.width;

    CGRect f = self.frame;
    f.size     = CGSizeMake(f.size.width, 1);
    self.frame = f;
    f.size     = [self sizeThatFits:CGSizeZero];
    self.frame = f;
}

// Force web view links to open in Safari.
// From: http://stackoverflow.com/a/2532884

- (void)webView:(WKWebView*)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURLRequest* request = navigationAction.request;
    NSURL* requestURL     = [request URL];
    if (
        (
            [[requestURL scheme] isEqualToString:@"http"]
            ||
            [[requestURL scheme] isEqualToString:@"https"]
            ||
            [[requestURL scheme] isEqualToString:@"mailto"])
        && (navigationAction.navigationType == WKNavigationTypeLinkActivated)
        ) {
        [self.externalLinksOpenerDelegate wmf_openExternalUrl:requestURL];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end

NS_ASSUME_NONNULL_END
