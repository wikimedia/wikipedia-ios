//  Created by Monte Hurd on 1/15/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UINavigationController+TopActionSheet.h"
#import "UIView+RemoveConstraints.h"
#import "UIView+WMFSearchSubviews.h"

#define ANIMATION_DURATION 0.23f

@implementation UINavigationController (TopActionSheet)

- (void)topActionSheetShowWithViews:(NSArray*)views orientation:(TabularScrollViewOrientation)orientation {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        TabularScrollView* containerView = nil;

        UIView* superView = self.view;

        // Reuse existing container if any.
        containerView = [superView wmf_firstSubviewOfClass:[TabularScrollView class]];

        // Remove container view if no views were specified.
        if (!views || (views.count == 0)) {
            if (containerView) {
                [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    [self constrainContainerView:containerView onScreen:NO];
                    [self.view layoutIfNeeded];
                } completion:^(BOOL done){
                    [containerView removeFromSuperview];
                }];
            }
            return;
        }

        // If no container to reuse, add one.
        if (!containerView) {
            containerView = [[TabularScrollView alloc] init];
            if (superView) {
                [superView insertSubview:containerView belowSubview:self.navigationBar];
                //[superView addSubview:containerView];

                // First constrain container above the nav bar so it can be animated coming down.
                [self constrainContainerView:containerView onScreen:NO];
                [self.view layoutIfNeeded];

                // Animate container coming down onscreen.
                [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    containerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];

                    [self constrainContainerView:containerView onScreen:YES];
                    [self.view layoutIfNeeded];
                } completion:^(BOOL done){
                }];
            }
        }

        containerView.orientation = orientation;
        containerView.tabularSubviews = views;
    }];
}

- (void)topActionSheetChangeOrientation:(TabularScrollViewOrientation)orientation {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        TabularScrollView* containerView = [self.view wmf_firstSubviewOfClass:[TabularScrollView class]];

        [containerView setOrientation:orientation];
    }];
}

- (void)topActionSheetHide {
    [self topActionSheetShowWithViews:nil orientation:TABULAR_SCROLLVIEW_LAYOUT_VERTICAL];
}

- (void)constrainContainerView:(UIView*)containerView onScreen:(BOOL)onScreen {
    // Remove existing containerView constraints.
    [containerView removeConstraintsOfViewFromView:self.view];

    NSDictionary* views = @{@"view": containerView, @"navBar": self.navigationBar};

    NSString* verticalConstraint = (onScreen) ? @"V:[navBar][view]|" : @"V:[view][navBar]";

    NSArray* constraints =
        @[
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(-1)-[view]-(-1)-|"
                                                options:0
                                                metrics:nil
                                                  views:views
        ],

        [NSLayoutConstraint constraintsWithVisualFormat:verticalConstraint
                                                options:0
                                                metrics:nil
                                                  views:views
        ]
    ];

    [self.view addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];

    [self.view setNeedsUpdateConstraints];
}

@end
