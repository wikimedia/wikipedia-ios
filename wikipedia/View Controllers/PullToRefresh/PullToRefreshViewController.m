//  Created by Brion on 7/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PullToRefreshViewController.h"
#import "Defines.h"

@interface PullToRefreshViewController ()

@property (strong, nonatomic) NSLayoutConstraint* pullToRefreshViewBottomConstraint;
@property (strong, nonatomic) UILabel* pullToRefreshLabel;
@property (nonatomic) BOOL isAnimatingHide;

@end

@implementation PullToRefreshViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.isAnimatingHide = NO;

    // Take over the scroll view's delegate
    UIScrollView* scrollView = [self refreshScrollView];
    if (scrollView) {
        scrollView.delegate = self;
        [self setupPullToRefresh];
    }
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if (self.isAnimatingHide || !self.pullToRefreshView) {
        return;
    }

    //NSUInteger numberToSkip = 2;
    //static NSInteger counter = -1;
    //if (++counter == numberToSkip) {
    [self updatePullToRefreshForScrollView:scrollView];
    //    counter = -1;
    //}
}

#pragma mark - Internal methods

- (void)setupPullToRefresh {
    self.pullToRefreshLabel                                           = [[UILabel alloc] init];
    self.pullToRefreshLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pullToRefreshLabel.textAlignment                             = NSTextAlignmentCenter;
    self.pullToRefreshLabel.numberOfLines                             = 2;
    self.pullToRefreshLabel.font                                      = [UIFont systemFontOfSize:10.0 * MENUS_SCALE_MULTIPLIER];
    self.pullToRefreshLabel.textColor                                 = [UIColor darkGrayColor];

    self.pullToRefreshView                                           = [[UIView alloc] init];
    self.pullToRefreshView.alpha                                     = 0.0f;
    self.pullToRefreshView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pullToRefreshView];
    [self.pullToRefreshView addSubview:self.pullToRefreshLabel];

    [self constrainPullToRefresh];
}

- (void)constrainPullToRefresh {
    self.pullToRefreshViewBottomConstraint =
        [NSLayoutConstraint constraintWithItem:self.pullToRefreshView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.view
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0];

    NSDictionary* viewsDictionary =
        @{
        @"pullToRefreshView": self.pullToRefreshView,
        @"pullToRefreshLabel": self.pullToRefreshLabel,
        @"selfView": self.view
    };

    NSArray* viewConstraintArrays =
        @[
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pullToRefreshView]|"
                                                options:0
                                                metrics:nil
                                                  views:viewsDictionary],
        @[self.pullToRefreshViewBottomConstraint],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[pullToRefreshLabel]-|"
                                                options:0
                                                metrics:nil
                                                  views:viewsDictionary],
        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[pullToRefreshLabel]|"
                                                options:0
                                                metrics:nil
                                                  views:viewsDictionary],
    ];

    [self.view addConstraints:[viewConstraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

- (void)updatePullToRefreshForScrollView:(UIScrollView*)scrollView {
    CGFloat pullDistance = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? 85.0f : 55.0f;

    pullDistance *= MENUS_SCALE_MULTIPLIER;

    UIPanGestureRecognizer* panRecognizer = scrollView.panGestureRecognizer;
    //CGPoint translation = [panRecognizer translationInView:self.view];

    BOOL safeToShow =
        (!scrollView.decelerating)
        &&
        (panRecognizer.state == UIGestureRecognizerStateChanged)
        &&
        [self refreshShouldShow];

    //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
    if ((scrollView.contentOffset.y < 0.0f)) {
        self.pullToRefreshViewBottomConstraint.constant = -scrollView.contentOffset.y;
        //self.pullToRefreshViewBottomConstraint.constant = -(fmaxf(scrollView.contentOffset.y, -self.pullToRefreshView.frame.size.height));

        if (safeToShow) {
            self.pullToRefreshView.alpha = 1.0f;
        }

        NSString* lineOneText = @"";
        NSString* lineTwoText = [self refreshPromptString];

        // pullUnit is 0.0 to 1.0
        CGFloat pullUnit = fabsf(scrollView.contentOffset.y) / pullDistance;
        //NSLog(@"%f", pullUnit);

        if (pullUnit < 0.35) {
            lineOneText = @"▫︎ ▫︎ ▫︎ ▫︎ ▫︎\n";
        } else if (pullUnit < 0.52) {
            lineOneText = @"▫︎ ▫︎ ▪︎ ▫︎ ▫︎\n";
        } else if (pullUnit < 1.0) {
            lineOneText = @"▫︎ ▪︎ ▪︎ ▪︎ ▫︎\n";
        } else {
            lineOneText = @"▪︎ ▪︎ ▪︎ ▪︎ ▪︎\n";
            lineTwoText = [self refreshRunningString];
        }

        self.pullToRefreshLabel.text = [lineOneText stringByAppendingString:lineTwoText];
    } else {
        self.pullToRefreshViewBottomConstraint.constant = 0;
    }

    if (scrollView.contentOffset.y < -pullDistance) {
        if (safeToShow) {
            [self refreshWasPulled];
            [self hideWithAnimation:scrollView];
        }
    }
}

- (void)hideWithAnimation:(UIScrollView*)scrollView {
    self.isAnimatingHide = YES;
    [UIView animateWithDuration:0.3f
                          delay:0.6f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.pullToRefreshView.alpha = 0.0f;
        self.pullToRefreshViewBottomConstraint.constant = 0;
        scrollView.panGestureRecognizer.enabled = NO;
        [self.view layoutIfNeeded];
    } completion:^(BOOL done){
        scrollView.panGestureRecognizer.enabled = YES;
        self.isAnimatingHide = NO;
    }];
}

#pragma mark - override these

- (UIScrollView*)refreshScrollView {
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        return (UIScrollView*)self.view;
    } else {
        NSLog(@"Override -refreshScrollView to return the correct view");
        return nil;
    }
}

/**
 * Get a localized string to show when pulling, before activation
 */
- (NSString*)refreshPromptString {
    return @"Refresh (not localized)";
}

/**
 * Get a localized string to show during refresh
 */
- (NSString*)refreshRunningString {
    return @"Refreshing (not localized)";
}

- (void)refreshWasPulled {
    NSLog(@"Don't forget to override refreshWasPulled");
}

- (BOOL)refreshShouldShow {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
