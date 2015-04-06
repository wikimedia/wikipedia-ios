//  Created by Monte Hurd on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+WMFTrackingView.h"
#import "UIView+WMFSearchSubviews.h"

@implementation UIWebView (TrackingView)

- (void)wmf_addTrackingView:(UIView*)view
                 atLocation:(WMFTrackingViewLocation)location {
    view.translatesAutoresizingMaskIntoConstraints = NO;

    UIView* webScrollView = self.scrollView;
    [webScrollView addSubview:view];

    // Reminder - this webView subview has the sizes we want constrain
    // "view" to, but the constraints themselves need to be added to
    // the webView's scrollView.
    UIView* browserView = [self.scrollView wmf_firstSubviewOfClass:NSClassFromString(@"UIWebBrowserView")];
    NSParameterAssert(browserView);
    void (^ constrainEqually)(NSLayoutAttribute) = ^(NSLayoutAttribute attr) {
        [webScrollView addConstraint:
         [NSLayoutConstraint constraintWithItem:view
                                      attribute:attr
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:browserView
                                      attribute:attr
                                     multiplier:1.0
                                       constant:0.0]
        ];
    };

    constrainEqually([self layoutAttributeForTrackingViewLocation:location]);
    constrainEqually(NSLayoutAttributeLeading);
    constrainEqually(NSLayoutAttributeWidth);
}

- (NSLayoutAttribute)layoutAttributeForTrackingViewLocation:(WMFTrackingViewLocation)location {
    switch (location) {
        case WMFTrackingViewLocationTop:
            return NSLayoutAttributeTop;
            break;
        case WMFTrackingViewLocationBottom:
            return NSLayoutAttributeBottom;
            break;
    }
}

@end
