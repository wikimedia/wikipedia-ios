//  Created by Monte Hurd on 7/25/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ReferenceVC.h"
#import "WebViewController.h"
#import "SessionSingleton.h"
#import "MWLanguageInfo.h"
#import "WikipediaAppUtils.h"
#import "WKWebView+ElementLocation.h"
#import "Defines.h"
#import "UIScrollView+WMFScrollsToTop.h"
#import "MediaWikiKit.h"
#import "UIViewController+WMFOpenExternalUrl.h"

#define REFERENCE_LINK_COLOR @"#2b6fb2"

@interface ReferenceVC ()

@property (weak, nonatomic) IBOutlet UIWebView* referenceWebView;

@end

@implementation ReferenceVC

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString* domain             = [SessionSingleton sharedInstance].currentArticleSiteURL.wmf_language;
    MWLanguageInfo* languageInfo = [MWLanguageInfo languageInfoForCode:domain];
    NSString* baseUrl            = [NSString stringWithFormat:@"https://%@.wikipedia.org/", languageInfo.code];

    //NSLog(@"request = %@ \ntype = %d", request, navigationType);
    switch (navigationType) {
        case UIWebViewNavigationTypeOther:
            // YES allows the reference html to actually be loaded/displayed.
            return YES;
            break;
        case UIWebViewNavigationTypeLinkClicked: {
            NSURL* requestURL = [request URL];

            // Jump to fragment.
            if ([requestURL.absoluteString hasPrefix:[NSString stringWithFormat:@"%@%@", baseUrl, @"#"]]) {
                [self.delegate referenceViewController:self didSelectInternalReferenceWithFragment:requestURL.fragment];
                return NO;
            }

            // Open wiki link in the WebViewController's web view.
            if ([requestURL.absoluteString hasPrefix:[NSString stringWithFormat:@"%@%@", baseUrl, @"wiki/"]]) {
#pragma warning Assuming that the url is on the same language wiki - what about other wikis?
                [self.delegate referenceViewController:self didSelectReferenceWithURL:requestURL];

                return NO;
            }

            // Open external link in Safari.
            NSString* scheme = [requestURL scheme];
            if (
                [scheme isEqualToString:@"http"]
                ||
                [scheme isEqualToString:@"https"]
                ||
                [scheme isEqualToString:@"mailto"]
                ) {
                [self.delegate referenceViewController:self didSelectExternalReferenceWithURL:requestURL];
                return NO;
            }
        }
        default:
            return NO;
            break;
    }
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // Prevent this web view from blocking the article web view from scrolling to top
    // when title bar tapped. (Only one scroll view can have scrollsToTop set to YES for
    // the title bar tap to cause scroll-to-top.)
    [self.referenceWebView.scrollView wmf_shouldScrollToTopOnStatusBarTap:NO];

    self.referenceWebView.delegate = self;

    NSString* domain             = [SessionSingleton sharedInstance].currentArticleSiteURL.wmf_language;
    MWLanguageInfo* languageInfo = [MWLanguageInfo languageInfoForCode:domain];
    NSString* baseUrl            = [NSString stringWithFormat:@"https://%@.wikipedia.org/", languageInfo.code];

    CGFloat fontSize = 14.0 * MENUS_SCALE_MULTIPLIER;
    CGFloat padding  = 10.0 * MENUS_SCALE_MULTIPLIER;

    NSString* html = [NSString stringWithFormat:@"\
<html>\
<head>\
<base href='%@' target='_self'>\
<style>\
    *{\
        color:#999;\
        font-family:'Helvetica Neue';\
        font-size:%fpt;\
        font-weight:normal;\
        line-height:148%%;\
        font-style:normal;\
        -webkit-text-size-adjust: none;\
        -webkit-hyphens: auto;\
        word-break: break-word;\
     }\
    BODY{\
        padding-left:%f;\
        padding-right:%f;\
     }\
    A, A *{\
        color:%@;\
        text-decoration:none;\
    }\
</style>\
</head>\
<body style='background-color:black;' lang='%@' dir='%@'>\
%@ %@\
</body>\
</html>\
", baseUrl, fontSize, padding, padding, REFERENCE_LINK_COLOR, languageInfo.code, languageInfo.dir, self.linkText, self.html];

    [self.referenceWebView loadHTMLString:html baseURL:[NSURL URLWithString:@""]];

    CGFloat topInset = 35.0 * MENUS_SCALE_MULTIPLIER;

    CGFloat bottomInset = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? 0 : topInset;

    self.referenceWebView.scrollView.contentInset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0);

    //self.webView.layer.borderColor = [UIColor whiteColor].CGColor;
    //self.webView.layer.borderWidth = 25;

    //self.view.layer.borderColor = [UIColor whiteColor].CGColor;
    //self.view.layer.borderWidth = 1;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.delegate referenceViewController:self didShowReferenceWithLinkID:self.linkId];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.delegate referenceViewController:self didFinishShowingReferenceWithLinkID:self.linkId];
    [super viewWillDisappear:animated];
}

@end
