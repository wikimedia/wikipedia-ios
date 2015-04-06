//  Created by Monte Hurd on 1/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PreviewWebView.h"
#import "SessionSingleton.h"
#import "UIWebView+HideScrollGradient.h"

@interface PreviewWebView ()

@end

@implementation PreviewWebView

//TODO: override "loadHTMLString:baseURL:" to add reference to css/js on server.
- (void)loadHTMLString:(NSString*)string baseURL:(NSURL*)baseURL {
    [super loadHTMLString:string baseURL:baseURL];
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];

        self.delegate               = self;
        self.userInteractionEnabled = YES;

        self.dataDetectorTypes = UIDataDetectorTypeNone;

        [self hideScrollGradient];
    }
    return self;
}

// Force web view links to open in Safari.
// From: http://stackoverflow.com/a/2532884
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSURL* requestURL = [request URL];
    if (
        (
            [[requestURL scheme] isEqualToString:@"http"]
            ||
            [[requestURL scheme] isEqualToString:@"https"]
            ||
            [[requestURL scheme] isEqualToString:@"mailto"])
        && (navigationType == UIWebViewNavigationTypeLinkClicked)
        ) {
        return ![[UIApplication sharedApplication] openURL:requestURL];
    }
    return YES;
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

/*
   // Only override drawRect: if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   - (void)drawRect:(CGRect)rect
   {
    // Drawing code
   }
 */

@end
