#import "WMFRandomDiceButton.h"
@import WebKit;
@import WMF;

@interface WMFRandomDiceButton ()
@property (nonatomic, strong) WMFTheme *theme;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UILabel *label;
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

    self.label = [[UILabel alloc] initWithFrame:CGRectZero];
    self.label.textColor = [UIColor whiteColor];
    self.label.font = [WMFFontWrapper fontFor:WMFFontsCallout compatibleWithTraitCollection:self.traitCollection];
    self.label.adjustsFontSizeToFitWidth = YES;
    self.label.minimumScaleFactor = 0.1;
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.text = [WMFCommonStrings randomizerTitle];
    [self addSubview:self.label];

    [self.widthAnchor constraintEqualToConstant:self.frame.size.width].active = YES;
    [self.heightAnchor constraintEqualToConstant:self.frame.size.height].active = YES;
}

- (void)roll {
    NSURL *diceJSURL = [[NSBundle mainBundle] URLForResource:@"WMFRandomDiceButtonRoll" withExtension:@"js"];
    NSString *diceJS = [NSString stringWithContentsOfURL:diceJSURL encoding:NSUTF8StringEncoding error:nil];
    [self.webView evaluateJavaScript:diceJS
                   completionHandler:^(id _Nullable obj, NSError *_Nullable error) {
                       DDLogWarn(@"%@", error);
                   }];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat margin = 15;
    self.webView.frame = CGRectMake(margin, 0, self.bounds.size.height, self.bounds.size.height);

    CGFloat spacing = 4;
    CGFloat labelOriginY = self.bounds.size.height + spacing + margin;
    self.label.frame = CGRectMake(labelOriginY, 0, self.bounds.size.width - labelOriginY - margin - spacing, self.bounds.size.height);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.layer.cornerRadius = 0.5 * frame.size.height;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.layer.cornerRadius = 0.5 * bounds.size.height;
}

- (void)applyTheme:(WMFTheme *)theme {
    if (theme == self.theme) {
        return; // early return to prevent cutting off dice animation when re-setting the same theme
    }
    self.theme = theme;
    NSURL *diceHTMLURL = [[NSBundle mainBundle] URLForResource:@"WMFRandomDiceButton" withExtension:@"html"];
    NSString *diceHTML = [NSString stringWithContentsOfURL:diceHTMLURL encoding:NSUTF8StringEncoding error:nil];
    // !-- Using stringWithFormat: and localizedStringWithFormat: caused issues with the dice rendering. Using stringByReplacingOccurrencesOfString instead --! //
    NSString *diceHTMLWithColor = [diceHTML stringByReplacingOccurrencesOfString:@"%1$@" withString:theme.colors.link.wmf_hexString];
    [self.webView loadHTMLString:diceHTMLWithColor baseURL:nil];
    self.backgroundColor = theme.colors.link;
}
@end
