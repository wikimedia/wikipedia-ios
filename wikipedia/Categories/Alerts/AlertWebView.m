//  Created by Monte Hurd on 1/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AlertWebView.h"
#import "SessionSingleton.h"

#define ALERT_WEB_VIEW_BAR_HEIGHT 50
#define ALERT_WEB_VIEW_BANNER_BUTTON_HEIGHT 120

@interface AlertWebView ()

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIButton *bannerButton;

@end

@implementation AlertWebView

- (instancetype)initWithHtml: (NSString *)html
                 bannerImage: (UIImage *)bannerImage
                 bannerColor: (UIColor *)bannerColor
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.webView = [[UIWebView alloc] init];
        self.webView.backgroundColor = [UIColor whiteColor];

        self.webView.delegate = self;
        self.bannerButton = [[UIButton alloc] init];

        self.webView.translatesAutoresizingMaskIntoConstraints = NO;
        self.bannerButton.translatesAutoresizingMaskIntoConstraints = NO;

        self.bannerButton.backgroundColor = bannerColor;
        
        [self.bannerButton setImage:bannerImage forState:UIControlStateNormal];

        [self.bannerButton setAdjustsImageWhenHighlighted:NO];

        [self.bannerButton addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];

        self.userInteractionEnabled = YES;
        self.bannerButton.userInteractionEnabled = YES;

        [self addSubview:self.webView];
        [self addSubview:self.bannerButton];
        
        // If a banner image was specified, but no HTML, make the web view background transparent.
        if(!html || html.length == 0){
            self.backgroundColor = [UIColor clearColor];
            [self.webView setBackgroundColor:[UIColor clearColor]];
            [self.webView setOpaque:NO];
        }
        
        NSURL *baseUrl = [[SessionSingleton sharedInstance] urlForLanguage:[SessionSingleton sharedInstance].site.language];
        
        [self.webView loadHTMLString:html baseURL:baseUrl];
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

-(void)tap
{
    [self removeFromSuperview];
}

-(void)removeFromSuperview
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HtmlAlertWasHidden" object:self userInfo:nil];

    [super removeFromSuperview];
}

-(void)updateConstraints{
    [super updateConstraints];
    [self addConstraints];
}

-(void)addConstraints
{
    [self removeConstraints:self.constraints];
    
    NSDictionary *viewsDictionary = @{
        @"webView": self.webView,
        @"bannerButton": self.bannerButton
    };

    CGFloat bannerButtonHeight = (self.bannerButton.imageView.image) ? ALERT_WEB_VIEW_BANNER_BUTTON_HEIGHT : 0 ;
    CGFloat barHeight = ALERT_WEB_VIEW_BAR_HEIGHT;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        bannerButtonHeight /= 2;
        barHeight /= 1.5;
    }

    NSDictionary *metrics = @{
        @"barHeight" : @(barHeight),
        @"bannerButtonHeight" : @(bannerButtonHeight)
    };

    NSArray *viewConstraintArrays = @
        [
         [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[webView]|"
                                                 options: 0
                                                 metrics: nil
                                                   views: viewsDictionary],
         
         [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[bannerButton]|"
                                                 options: 0
                                                 metrics: nil
                                                   views: viewsDictionary],
         
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[bannerButton(bannerButtonHeight)][webView]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: viewsDictionary],
     ];

    [self addConstraints:[viewConstraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

-(void)layoutSubviews
{
    [self setNeedsDisplay];
    [self setNeedsUpdateConstraints];
    [super layoutSubviews];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (!self.bannerButton.imageView.image) {
        CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect) + ALERT_WEB_VIEW_BAR_HEIGHT);
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect) + ALERT_WEB_VIEW_BAR_HEIGHT);
    }

    CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect));

    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor] );
    CGContextSetLineWidth(context, 1.0f / [UIScreen mainScreen].scale);
    CGContextStrokePath(context);
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
