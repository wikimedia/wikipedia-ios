//  Created by Monte Hurd on 1/15/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UINavigationController+Alert.h"
#import "AlertLabel.h"
#import "AlertWebView.h"

@implementation UINavigationController (Alert)

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
            if (alertContainer) {
                [alertContainer addSubview:alertLabel];
                [self constrainAlertView:alertLabel fullScreen:NO];
            }
        }
        
        alertLabel.text = alertText;
    }];
}

-(void)showHTMLAlert: (NSString *)html
      bannerImage: (UIImage *)bannerImage
      bannerColor: (UIColor *)bannerColor
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        AlertWebView *alertWebView = nil;
        
        //UIView *alertContainer = self.view;
        // Tack html alert on to the view controller's view so html alert animates sliding
        // offscreen when the view does.
        UIView *alertContainer = self.topViewController.view;

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

-(void)constrainAlertView:(UIView *)view fullScreen:(BOOL)isFullScreen
{
    CGFloat topMargin = 0.0f;
    id navBar = self.navigationBar;
    NSDictionary *views = NSDictionaryOfVariableBindings (view, navBar);
    NSDictionary *metrics = @{@"space": @(topMargin)};

    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
                                             options: 0
                                             metrics: nil
                                               views: views
      ]
     ];
    
    NSString *verticalConstraint = [NSString stringWithFormat:@"V:[navBar]-(space)-[view]%@", (isFullScreen) ? @"|": @""];
    
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
