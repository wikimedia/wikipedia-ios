//  Created by Monte Hurd on 1/29/14.

#import "AlertWebView.h"
#import "SessionSingleton.h"

#define ALERT_WEB_VIEW_BAR_HEIGHT 50
#define ALERT_WEB_VIEW_BANNER_BUTTON_HEIGHT 120

@interface AlertWebView ()

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIButton *bannerButton;
@property (strong, nonatomic) UIButton *leftButton;
@property (strong, nonatomic) UIButton *rightButton;

@end

@implementation AlertWebView

- (instancetype)initWithHtml: (NSString *)html
                   leftImage: (UIImage *)leftImage
                   labelText: (NSString *)labelText
                  rightImage: (UIImage *)rightImage
                 bannerImage: (UIImage *)bannerImage
                 bannerColor: (UIColor *)bannerColor
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.webView = [[UIWebView alloc] init];
        self.webView.backgroundColor = [UIColor whiteColor];

        self.webView.delegate = self;
        self.rightButton = [[UIButton alloc] init];
        self.leftButton = [[UIButton alloc] init];
        self.label = [[UILabel alloc] init];
        self.bannerButton = [[UIButton alloc] init];

        self.webView.translatesAutoresizingMaskIntoConstraints = NO;
        self.rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.bannerButton.translatesAutoresizingMaskIntoConstraints = NO;

        self.label.text = labelText;
        self.bannerButton.backgroundColor = bannerColor;
        
        [self.bannerButton setImage:bannerImage forState:UIControlStateNormal];
        [self.leftButton setImage:leftImage forState:UIControlStateNormal];
        [self.rightButton setImage:rightImage forState:UIControlStateNormal];

        [self.bannerButton setAdjustsImageWhenHighlighted:NO];

        self.rightButton.alpha = 0.7;

        self.label.backgroundColor = [UIColor clearColor];

        self.label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
        self.label.textColor = [UIColor darkGrayColor];

        
        [self.leftButton addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
        [self.rightButton addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
        [self.bannerButton addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];

        self.label.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        [self.label addGestureRecognizer:tap];

        self.userInteractionEnabled = YES;
        self.leftButton.userInteractionEnabled = YES;
        self.rightButton.userInteractionEnabled = YES;
        self.label.userInteractionEnabled = YES;
        self.bannerButton.userInteractionEnabled = YES;

        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        self.label.numberOfLines = 10;

        [self addSubview:self.webView];
        [self addSubview:self.leftButton];
        [self addSubview:self.rightButton];
        [self addSubview:self.label];
        [self addSubview:self.bannerButton];
        
        NSURL *baseUrl = [[SessionSingleton sharedInstance] urlForDomain:[SessionSingleton sharedInstance].currentArticleDomain];
        
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

-(void)updateConstraints{
    [super updateConstraints];
    [self addConstraints];
}

-(void)addConstraints
{
    [self removeConstraints:self.constraints];
    
    NSDictionary *viewsDictionary = @{
        @"webView": self.webView,
        @"leftButton": self.leftButton,
        @"rightButton": self.rightButton,
        @"label": self.label,
        @"bannerButton": self.bannerButton
    };

    CGFloat leftButtonWidth = (self.leftButton.imageView.image) ? ALERT_WEB_VIEW_BAR_HEIGHT : 0 ;
    CGFloat bannerButtonHeight = (self.bannerButton.imageView.image) ? ALERT_WEB_VIEW_BANNER_BUTTON_HEIGHT : 0 ;
    CGFloat barHeight = ALERT_WEB_VIEW_BAR_HEIGHT;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        bannerButtonHeight /= 2;
        barHeight /= 1.5;
        leftButtonWidth /= 1.5;
    }

    NSDictionary *metrics = @{
        @"barHeight" : @(barHeight),
        @"bannerButtonHeight" : @(bannerButtonHeight),
        @"leftButtonWidth" : @(leftButtonWidth)
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
         
         [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[leftButton(leftButtonWidth)]-[label]-[rightButton(barHeight)]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: viewsDictionary],
         
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[rightButton(barHeight)][bannerButton(bannerButtonHeight)][webView]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: viewsDictionary],
         
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[leftButton(barHeight)][bannerButton(bannerButtonHeight)][webView]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: viewsDictionary],
         
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[label(barHeight)][bannerButton(bannerButtonHeight)][webView]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: viewsDictionary]
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

    CGFloat space = 7.0f;

    if (!self.bannerButton.imageView.image) {
        CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect) + ALERT_WEB_VIEW_BAR_HEIGHT);
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect) + ALERT_WEB_VIEW_BAR_HEIGHT);
    }

    CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect));

    if (self.leftButton.imageView.image) {
        CGContextMoveToPoint(context, self.leftButton.frame.origin.x + self.leftButton.frame.size.width, CGRectGetMinY(rect) + space);
        CGContextAddLineToPoint(context, self.leftButton.frame.origin.x + self.leftButton.frame.size.width, CGRectGetMaxY(rect));
    }

    if (self.rightButton.imageView.image) {
        CGContextMoveToPoint(context, self.rightButton.frame.origin.x, CGRectGetMinY(rect) + space);
        CGContextAddLineToPoint(context, self.rightButton.frame.origin.x, CGRectGetMaxY(rect));
    }

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
