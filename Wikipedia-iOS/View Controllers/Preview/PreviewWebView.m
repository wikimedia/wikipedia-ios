//  Created by Monte Hurd on 1/29/14.

#import "PreviewWebView.h"
#import "SessionSingleton.h"
#import "UIWebView+HideScrollGradient.h"

@interface PreviewWebView ()

@end

@implementation PreviewWebView

//TODO: override "loadHTMLString:baseURL:" to add reference to css/js on server.
-(void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    [super loadHTMLString:string baseURL:baseURL];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {

        self.backgroundColor = [UIColor whiteColor];

        self.delegate = self;
        self.userInteractionEnabled = YES;
        
        self.dataDetectorTypes = UIDataDetectorTypeNone;
        
        [self hideScrollGradient];
    }
    return self;
}

// Force web view links to open in Safari.
// From: http://stackoverflow.com/a/2532884
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType; 
{
    NSURL *requestURL = [request URL];
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
