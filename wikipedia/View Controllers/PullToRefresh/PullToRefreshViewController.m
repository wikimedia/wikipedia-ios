//
//  PullToRefreshViewController.m
//  Wikipedia
//
//  Created by Brion on 7/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "PullToRefreshViewController.h"

@interface PullToRefreshViewController ()

@end

@implementation PullToRefreshViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Take over the scroll view's delegate
    UIScrollView *scrollView = [self refreshScrollView];
    assert(scrollView != nil);
    scrollView.delegate = self;
    [self setupPullToRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updatePullToRefreshForScrollView:scrollView];
}


#pragma mark - Internal methods

-(void)setupPullToRefresh
{
    self.pullToRefreshLabel = [[UILabel alloc] init];
    self.pullToRefreshLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pullToRefreshLabel.backgroundColor = [UIColor clearColor];
    self.pullToRefreshLabel.textAlignment = NSTextAlignmentCenter;
    self.pullToRefreshLabel.numberOfLines = 2;
    self.pullToRefreshLabel.font = [UIFont systemFontOfSize:10];
    self.pullToRefreshLabel.textColor = [UIColor darkGrayColor];
    
    self.pullToRefreshView = [[UIView alloc] init];
    self.pullToRefreshView.alpha = 0.0f;
    self.pullToRefreshView.backgroundColor = [UIColor clearColor];
    self.pullToRefreshView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pullToRefreshView];
    [self.pullToRefreshView addSubview:self.pullToRefreshLabel];
    
    [self constrainPullToRefresh];
}

-(void)constrainPullToRefresh
{
    self.pullToRefreshViewBottomConstraint =
    [NSLayoutConstraint constraintWithItem: self.pullToRefreshView
                                 attribute: NSLayoutAttributeBottom
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.view
                                 attribute: NSLayoutAttributeTop
                                multiplier: 1.0
                                  constant: 0];
    
    NSDictionary *viewsDictionary = @{
                                      @"pullToRefreshView": self.pullToRefreshView,
                                      @"pullToRefreshLabel": self.pullToRefreshLabel,
                                      @"selfView": self.view
                                      };
    
    NSArray *viewConstraintArrays =
    @[
      [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[pullToRefreshView]|"
                                              options: 0
                                              metrics: nil
                                                views: viewsDictionary],
      @[self.pullToRefreshViewBottomConstraint],
      [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-[pullToRefreshLabel]-|"
                                              options: 0
                                              metrics: nil
                                                views: viewsDictionary],
      [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[pullToRefreshLabel]|"
                                              options: 0
                                              metrics: nil
                                                views: viewsDictionary],
      ];
    
    [self.view addConstraints:[viewConstraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

- (void)updatePullToRefreshForScrollView:(UIScrollView *)scrollView
{
    if (ROOT.isAnimatingTopAndBottomMenuHidden) return;
    
    CGFloat pullDistance = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? 85.0f : 55.0f;
    
    UIGestureRecognizerState state = ((UIPinchGestureRecognizer *)scrollView.pinchGestureRecognizer).state;
    
    BOOL safeToShow =
    (!scrollView.decelerating)
    &&
    (state == UIGestureRecognizerStatePossible)
    &&
    [self refreshShouldShow]
    ;
    
    //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
    if ((scrollView.contentOffset.y < 0.0f)){
        
        self.pullToRefreshViewBottomConstraint.constant = -scrollView.contentOffset.y;
        //self.pullToRefreshViewBottomConstraint.constant = -(fmaxf(scrollView.contentOffset.y, -self.pullToRefreshView.frame.size.height));
        
        if (safeToShow) {
            self.pullToRefreshView.alpha = 1.0f;
        }
        
        NSString *lineOneText = @"";
        NSString *lineTwoText = [self refreshPromptString];
        
        if (scrollView.contentOffset.y > -(pullDistance * 0.35)){
            lineOneText = @"▫︎ ▫︎ ▫︎ ▫︎ ▫︎";
        }else if (scrollView.contentOffset.y > -(pullDistance * 0.52)){
            lineOneText = @"▫︎ ▫︎ ▪︎ ▫︎ ▫︎";
        }else if (scrollView.contentOffset.y > -(pullDistance * 0.7)){
            lineOneText = @"▫︎ ▪︎ ▪︎ ▪︎ ▫︎";
        }else if (scrollView.contentOffset.y > -pullDistance){
            lineOneText = @"▫︎ ▪︎ ▪︎ ▪︎ ▫︎";
        }else{
            lineOneText = @"▪︎ ▪︎ ▪︎ ▪︎ ▪︎";
            lineTwoText = [self refreshRunningString];
        }
        
        self.pullToRefreshLabel.text = [NSString stringWithFormat:@"%@\n%@", lineOneText, lineTwoText];
    }
    
    if (scrollView.contentOffset.y < -pullDistance) {
        if (safeToShow) {
            [self refreshWasPulled];
            [UIView animateWithDuration: 0.3f
                                  delay: 0.6f
                                options: UIViewAnimationOptionTransitionNone
                             animations: ^{
                                 self.pullToRefreshView.alpha = 0.0f;
                                 self.pullToRefreshViewBottomConstraint.constant = 0;
                                 [self.view layoutIfNeeded];
                                 scrollView.panGestureRecognizer.enabled = NO;
                             } completion: ^(BOOL done){
                                 scrollView.panGestureRecognizer.enabled = YES;
                             }];
        }
    }
}

#pragma mark - override these

-(UIScrollView *)refreshScrollView
{
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        return (UIScrollView *)self.view;
    } else {
        NSLog(@"Override -refreshScrollView to return the correct view");
        return nil;
    }
}

/**
 * Get a localized string to show when pulling, before activation
 */
-(NSString *)refreshPromptString
{
    return @"Refresh (not localized)";
}

/**
 * Get a localized string to show during refresh
 */
-(NSString *)refreshRunningString
{
    return @"Refreshing (not localized)";
}


-(void)refreshWasPulled
{
    NSLog(@"Don't forget to override refreshWasPulled");
}

-(BOOL)refreshShouldShow
{
    return YES;
}

@end
