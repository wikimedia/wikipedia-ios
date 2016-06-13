//  Created by Monte Hurd on 1/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PreviewWebViewContainer.h"
#import <Masonry/Masonry.h>
#import "Wikipedia-Swift.h"
#import "WKProcessPool+WMFSharedProcessPool.h"

NS_ASSUME_NONNULL_BEGIN

@interface PreviewWebViewContainer () <WKScriptMessageHandler>

@end

@implementation PreviewWebViewContainer

- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message {
    if ([message.name isEqualToString:@"clicks"]) {
        if (message.body[@"anchorClicked"]) {
            NSString* href = message.body[@"anchorClicked"][@"href"];
            [self.previewAnchorTapAlertDelegate wmf_showAlertForTappedAnchorHref:href];
        }
    }
}

- (WKWebViewConfiguration*)configuration {
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];

    MWLanguageInfo* langInfo = [self.previewSectionLanguageInfoDelegate wmf_editedSectionLanguageInfo];
    NSString* uidir          = ([[UIApplication sharedApplication] wmf_isRTL] ? @"rtl" : @"ltr");

    NSString* earlyJavascriptTransforms =
        [NSString stringWithFormat:@""
         "document.onclick = function() {"
         "    event.preventDefault();"
         "        if (event.target.tagName == 'A'){"
         "            var href = event.target.getAttribute( 'href' );"
         "            window.webkit.messageHandlers.clicks.postMessage({'anchorClicked': { 'href': href }});"
         "        }"
         "};"
         "window.wmf.utilities.setLanguage('%@', '%@', '%@');",
         langInfo.code,
         langInfo.dir,
         uidir
        ];

    [userContentController addUserScript:
     [[WKUserScript alloc] initWithSource:earlyJavascriptTransforms
                            injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                         forMainFrameOnly:YES]];


    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"clicks"];


    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    configuration.processPool           = [WKProcessPool wmf_sharedProcessPool];
    return configuration;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    WKWebView* webview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self configuration]];
    webview.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:webview];
    self.webView                    = webview;
    self.backgroundColor            = [UIColor whiteColor];
    self.webView.navigationDelegate = self;
    self.userInteractionEnabled     = YES;
    [self.webView mas_makeConstraints:^(MASConstraintMaker* make) {
        make.top.bottom.leading.and.trailing.equalTo(self.webView.superview);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews]; // get width from solved constraints
    [self forceScrollViewContentSizeToReflectActualHTMLHeight];
}

- (void)forceScrollViewContentSizeToReflectActualHTMLHeight {
    // Only run this if the width has changed. Otherwise it will recurse endlessly.
    static CGFloat lastWidth = 0;
    if (lastWidth == self.webView.scrollView.frame.size.width) {
        return;
    }
    lastWidth = self.webView.scrollView.frame.size.width;

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
