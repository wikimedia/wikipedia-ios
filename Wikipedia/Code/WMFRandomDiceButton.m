#import "WMFRandomDiceButton.h"
@import WebKit;

@interface WMFRandomDiceButton ()
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation WMFRandomDiceButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.suppressesIncrementalRendering = YES;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    self.webView.userInteractionEnabled = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.scrollView.backgroundColor = [UIColor clearColor];
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.minimumZoomScale = 1;
    self.webView.scrollView.maximumZoomScale = 1;
    self.webView.opaque = NO;
    self.webView.scrollView.opaque = NO;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.webView];
    
    NSURL *diceHTMLURL = [[NSBundle mainBundle] URLForResource:@"WMFRandomDiceButton" withExtension:@"html"];
    NSString *diceHTML = [NSString stringWithContentsOfURL:diceHTMLURL encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:diceHTML baseURL:nil];
}

- (void)roll {
    NSURL *diceJSURL = [[NSBundle mainBundle] URLForResource:@"WMFRandomDiceButtonRoll" withExtension:@"js"];
    NSString *diceJS = [NSString stringWithContentsOfURL:diceJSURL encoding:NSUTF8StringEncoding error:nil];
    [self.webView evaluateJavaScript:diceJS completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

@end
