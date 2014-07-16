//  Created by Monte Hurd on 1/15/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+Alert.h"
#import "AlertLabel.h"
#import "AlertWebView.h"
#import "UIView+RemoveConstraints.h"

@implementation UIViewController (Alert)

-(void)showAlert:(NSString *)alertText
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        AlertLabel *alertLabel = nil;
        
        // Tack these alerts to the nav controller's view.
        UIView *alertContainer = self.view;
        
        // Reuse existing alert label if any.
        alertLabel = [self getExistingViewOfClass:[AlertLabel class] inContainer:alertContainer];
        
        // If none to reuse, add one.
        if (!alertLabel) {
            alertLabel = [[AlertLabel alloc] init];
            alertLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [alertContainer addSubview:alertLabel];
            [self constrainAlertView:alertLabel fullScreen:NO];
        }

        BOOL hide = [self shouldHideAlertForViewController:self];

        if (hide) {
            alertLabel.alpha = 0.0;
        }else{
            alertLabel.text = alertText;
        }

    }];
}

-(void)fadeAlert
{
    [self showAlert:@""];
}

-(void)hideAlert
{
    // Hide alert immediately. Removes it so any running fade animations don't prevent immediate hide.
    AlertLabel *alertLabel = [self getExistingViewOfClass:[AlertLabel class] inContainer:self.view];
    if (alertLabel) {
        [alertLabel removeConstraintsOfViewFromView:self.view];
        [alertLabel removeFromSuperview];
        alertLabel = nil;
    }
}

-(BOOL)shouldHideAlertForViewController:(UIViewController *)vc
{
    BOOL hideAlerts = NO;
    if ([vc respondsToSelector:NSSelectorFromString(@"prefersAlertsHidden")]) {
        SEL selector = NSSelectorFromString(@"prefersAlertsHidden");
        if ([vc respondsToSelector:selector]) {
            NSInvocation *invocation =
            [NSInvocation invocationWithMethodSignature: [[vc class] instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:vc];
            [invocation invoke];
            BOOL prefersAlertsHidden;
            [invocation getReturnValue:&prefersAlertsHidden];
            hideAlerts = (BOOL)prefersAlertsHidden;
        }
    }else{
        hideAlerts = NO;
    }
    return hideAlerts;
}

/*
-(BOOL)isTopNavHiddenForViewController:(UIViewController *)vc
{
    BOOL topNavHidden = NO;
    if ([vc respondsToSelector:NSSelectorFromString(@"prefersTopNavigationHidden")]) {
        SEL selector = NSSelectorFromString(@"prefersTopNavigationHidden");
        if ([vc respondsToSelector:selector]) {
            NSInvocation *invocation =
            [NSInvocation invocationWithMethodSignature: [[vc class] instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:vc];
            [invocation invoke];
            BOOL prefersTopNavHidden;
            [invocation getReturnValue:&prefersTopNavHidden];
            topNavHidden = (BOOL)prefersTopNavHidden;
        }
    }else{
        topNavHidden = NO;
    }
    
    return topNavHidden;
}
*/

-(void)showHTMLAlert: (NSString *)html
      bannerImage: (UIImage *)bannerImage
      bannerColor: (UIColor *)bannerColor
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        AlertWebView *alertWebView = nil;
        
        //UIView *alertContainer = self.view;
        // Tack html alert on to the view controller's view so html alert animates sliding
        // offscreen when the view does.
        UIView *alertContainer = self.view;

        // Remove existing alert web view if any.
        alertWebView = [self getExistingViewOfClass:[AlertWebView class] inContainer:alertContainer];
        if (alertWebView) {
            [alertWebView removeFromSuperview];
            alertWebView = nil;
        }
        
        if (!html || html.length == 0){
            if (!bannerImage) {
                return;
            }
        }

        alertWebView = [[AlertWebView alloc] initWithHtml: html
                                              bannerImage: bannerImage
                                              bannerColor: bannerColor
                        ];

        alertWebView.translatesAutoresizingMaskIntoConstraints = NO;

        if (alertContainer) {
            [alertContainer addSubview:alertWebView];
            [self constrainAlertView:alertWebView fullScreen:YES];
        }
    }];
}

-(void)hideHTMLAlert
{
    [self showHTMLAlert:nil bannerImage:nil bannerColor:nil];
}

-(void)constrainAlertView:(UIView *)view fullScreen:(BOOL)isFullScreen
{
    CGFloat topMargin = 0;//[self isTopNavHiddenForViewController:self] ? 20 : 0;

    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSDictionary *metrics = @{@"space": @(topMargin)};

    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
                                             options: 0
                                             metrics: nil
                                               views: views
      ]
     ];
    
    NSString *verticalConstraint = [NSString stringWithFormat:@"V:|-(space)-[view]%@", (isFullScreen) ? @"|": @""];
    
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: verticalConstraint
                                             options: 0
                                             metrics: metrics
                                               views: views
      ]
     ];
}

-(id)getExistingViewOfClass:(Class)class inContainer:(UIView *)container
{
    for (id view in container.subviews) {
        if ([view isMemberOfClass:class]) return view;
    }
    return nil;
}

@end
