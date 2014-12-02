//  Created by Monte Hurd on 11/10/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchTypeMenu.h"
#import "PaddedLabel.h"
#import "NSObject+ConstraintsScale.h"
#import "UIView+RoundCorners.h"
#import "WikipediaAppUtils.h"
#import "Defines.h"
#import "SearchResultFetcher.h"

#define FONT_SIZE (14.0f * MENUS_SCALE_MULTIPLIER)
#define CORNER_RADIUS (2.0f * MENUS_SCALE_MULTIPLIER)
#define CORNERS_LEFT (UIRectCornerTopLeft|UIRectCornerBottomLeft)
#define CORNERS_RIGHT (UIRectCornerTopRight|UIRectCornerBottomRight)
#define BACKGROUND_COLOR [UIColor whiteColor]
#define BORDER_WIDTH (1.0f / [UIScreen mainScreen].scale)
#define BUTTON_PADDING (UIEdgeInsetsMake(6.0f, 6.0f, 6.0f, 6.0f))
#define BUTTON_MARGIN (UIEdgeInsetsMake(10.0f, 12.0f, 10.0f, 12.0f))

@interface SearchTypeMenu()

@property (strong, nonatomic) PaddedLabel *searchButtonTitles;
@property (strong, nonatomic) PaddedLabel *searchButtonWithinArticles;

@end

@implementation SearchTypeMenu

-(void)setSearchType:(SearchType)type
{
    _searchType = type;
    switch (type) {
        case SEARCH_TYPE_TITLES:
            self.searchButtonTitles.backgroundColor = SEARCH_BUTTON_BACKGROUND_COLOR;
            self.searchButtonWithinArticles.backgroundColor = [UIColor whiteColor];
            self.searchButtonTitles.textColor = [UIColor whiteColor];
            self.searchButtonWithinArticles.textColor = SEARCH_BUTTON_BACKGROUND_COLOR;
            self.searchButtonTitles.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
            self.searchButtonWithinArticles.font = [UIFont systemFontOfSize:FONT_SIZE];
            break;
        case SEARCH_TYPE_IN_ARTICLES:
            self.searchButtonTitles.backgroundColor = [UIColor whiteColor];
            self.searchButtonWithinArticles.backgroundColor = SEARCH_BUTTON_BACKGROUND_COLOR;
            self.searchButtonTitles.textColor = SEARCH_BUTTON_BACKGROUND_COLOR;
            self.searchButtonWithinArticles.textColor = [UIColor whiteColor];
            self.searchButtonTitles.font = [UIFont systemFontOfSize:FONT_SIZE];
            self.searchButtonWithinArticles.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
            break;
        default:
            break;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.searchType = SEARCH_TYPE_TITLES;
    }
    return self;
}

-(void)setupButton:(PaddedLabel *)button
{
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.lineBreakMode = NSLineBreakByWordWrapping;
    button.numberOfLines = 0;
    button.padding = BUTTON_PADDING;
    button.userInteractionEnabled = YES;
    button.textAlignment = NSTextAlignmentCenter;
    [button addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapped:)]];
}

-(void)didMoveToSuperview
{
    if (!ENABLE_FULL_TEXT_SEARCH) {
        //self.backgroundColor = [UIColor clearColor];
        self.searchType = self.searchType;
        [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:[self(1)]"
                                                                               options: 0
                                                                               metrics: nil
                                                                                 views: @{@"self": self}]];
        return;
    }

    self.backgroundColor = BACKGROUND_COLOR;

    self.searchButtonTitles = [[PaddedLabel alloc] init];
    self.searchButtonWithinArticles = [[PaddedLabel alloc] init];

    [self setupButton:self.searchButtonTitles];
    [self setupButton:self.searchButtonWithinArticles];

    self.searchButtonTitles.tag = SEARCH_TYPE_TITLES;
    self.searchButtonWithinArticles.tag = SEARCH_TYPE_IN_ARTICLES;

    [self addSubview:self.searchButtonTitles];
    [self addSubview:self.searchButtonWithinArticles];

    [self constrainButtons];
    
    self.searchType = self.searchType;
    
    self.searchButtonTitles.text = MWLocalizedString(@"search-titles", nil);
    self.searchButtonWithinArticles.text = MWLocalizedString(@"search-within-articles", nil);

}

-(void)constrainButtons
{
    NSDictionary *views = @{
                            @"searchButtonTitles": self.searchButtonTitles,
                            @"searchButtonWithinArticles": self.searchButtonWithinArticles
                            };
    
    NSDictionary *metrics = @{
                              @"marginTop": @(BUTTON_MARGIN.top /* * MENUS_SCALE_MULTIPLIER*/),
                              @"marginBottom": @(BUTTON_MARGIN.bottom /* * MENUS_SCALE_MULTIPLIER*/),
                              @"marginLeft": @(BUTTON_MARGIN.left /* * MENUS_SCALE_MULTIPLIER*/),
                              @"marginRight": @(BUTTON_MARGIN.right /* * MENUS_SCALE_MULTIPLIER*/)
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|-marginLeft-[searchButtonTitles][searchButtonWithinArticles(==searchButtonTitles)]-marginRight-|"
                                                                 options: 0
                                                                 metrics: metrics
                                                                   views: views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:|-marginTop-[searchButtonTitles]-marginBottom-|"
                                                                 options: 0
                                                                 metrics: metrics
                                                                   views: views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:|-marginTop-[searchButtonWithinArticles]-marginBottom-|"
                                                                 options: 0
                                                                 metrics: metrics
                                                                   views: views]];
    
    [self adjustConstraintsScaleForViews:@[self.searchButtonTitles, self.searchButtonWithinArticles]];
}

-(void)layoutSubviews
{
    [super layoutSubviews];

    // "Autolayout won't recalculate your mask, so you will have to set the mask each time your layout changes."
    // http://stackoverflow.com/a/24043797
    [self.searchButtonTitles roundCorners:CORNERS_LEFT toRadius:CORNER_RADIUS];
    [self.searchButtonWithinArticles roundCorners:CORNERS_RIGHT toRadius:CORNER_RADIUS];
    [self setNeedsDisplay];
}

-(void)buttonTapped:(UIGestureRecognizer *)sender
{
    self.searchType = sender.view.tag;
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    // Makes very small gradient at bottom of menu so search results scrolling underneath
    // the menu blend more seamlessly.
    //[self drawGradientBackground:rect];

    // Hack to draw rounded borders exactly how we want them.
    [self drawRoundedBorders];
}

-(void)drawRoundedBorders
{
    // Hack to draw rounded borders (with inside curve rounding).

    [SEARCH_BUTTON_BACKGROUND_COLOR set];
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(currentContext, BORDER_WIDTH);
    CGContextSetLineCap(currentContext, kCGLineCapRound);
    CGContextSetLineJoin(currentContext, kCGLineJoinRound);
    CGContextBeginPath(currentContext);

    UIBezierPath *path1 =
    [UIBezierPath bezierPathWithRoundedRect: self.searchButtonTitles.frame
                          byRoundingCorners: CORNERS_LEFT
                                cornerRadii: CGSizeMake(CORNER_RADIUS, CORNER_RADIUS)];
    CGContextAddPath(currentContext, path1.CGPath);

    UIBezierPath *path2 =
    [UIBezierPath bezierPathWithRoundedRect: self.searchButtonWithinArticles.frame
                          byRoundingCorners: CORNERS_RIGHT
                                cornerRadii: CGSizeMake(CORNER_RADIUS, CORNER_RADIUS)];
    CGContextAddPath(currentContext, path2.CGPath);

    CGContextDrawPath(currentContext, kCGPathStroke);
}

- (void)drawGradientBackground:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Make the gradient begin just above the bottom.
    CGFloat gradientHeight = CGRectGetMaxY(rect) - (2.0 * MENUS_SCALE_MULTIPLIER);

    // Draw top part in white.
    CGRect topHalfRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, gradientHeight);
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(ctx, topHalfRect);

    // Draw white to transparent gradient of gradientHeight at bottom of rect.
    // Gradient drawing based on: http://stackoverflow.com/a/422208
    CGGradientRef gradient;
    CGColorSpaceRef rgbSpace;
    size_t locationCount = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat colorComponents[8] = {
        1.0, 1.0, 1.0, 1.0,    // starting color
        1.0, 1.0, 1.0, 0.0     // ending color
    };

    rgbSpace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents(rgbSpace, colorComponents, locations, locationCount);

    CGPoint midCenter = CGPointMake(CGRectGetMidX(rect), gradientHeight);
    CGPoint bottomCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGContextDrawLinearGradient(ctx, gradient, midCenter, bottomCenter, 0);

    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgbSpace);
}

@end
