//  Created by Monte Hurd on 1/15/14.

#import "UINavigationController+TopActionSheet.h"
#import "TopActionSheetScrollView.h"
#import "UIView+RemoveConstraints.h"

#define ANIMATION_DURATION 0.23f

@implementation UINavigationController (TopActionSheet)

-(void)topActionSheetShowWithViews: (NSArray *)views orientation: (TopActionSheetLayoutOrientation)orientation
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        TopActionSheetScrollView *containerView = nil;
        
        UIView *superView = self.view;
        
        // Reuse existing container if any.
        containerView = [self getExistingViewOfClass:[TopActionSheetScrollView class] inContainer:superView];

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
            containerView = [[TopActionSheetScrollView alloc] init];
            if (superView) {

                [superView insertSubview:containerView belowSubview:self.navigationBar];
                //[superView addSubview:containerView];

                // First constrain container above the nav bar so it can be animated coming down.
                [self constrainContainerView:containerView onScreen:NO];
                [self.view layoutIfNeeded];
                
                // Animate container coming down onscreen.
                [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{

                    containerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];

                    [self constrainContainerView:containerView onScreen:YES];
                    [self.view layoutIfNeeded];
                } completion:^(BOOL done){
                    
                }];
            }
        }

        containerView.orientation = orientation;
        containerView.topActionSheetSubviews = views;
    }];
}

-(void)topActionSheetChangeOrientation:(TopActionSheetLayoutOrientation)orientation
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        TopActionSheetScrollView *containerView = [self getExistingViewOfClass:[TopActionSheetScrollView class] inContainer:self.view];

        [containerView setOrientation:orientation];
            
    }];
}

-(void)topActionSheetHide
{
    [self topActionSheetShowWithViews:nil orientation:TOP_ACTION_SHEET_LAYOUT_VERTICAL];
}

-(void)constrainContainerView:(UIView *)containerView onScreen:(BOOL)onScreen
{
    // Remove existing containerView constraints.
    [containerView removeConstraintsOfViewFromView:self.view];

    NSDictionary *views = @{@"view": containerView, @"navBar": self.navigationBar};
    
    NSString *verticalConstraint = (onScreen) ? @"V:[navBar][view]|": @"V:[view][navBar]";
    
    NSArray *constraints =
    @[
       [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-(-1)-[view]-(-1)-|"
                                               options: 0
                                               metrics: nil
                                                 views: views
        ],
       
       [NSLayoutConstraint constraintsWithVisualFormat: verticalConstraint
                                               options: 0
                                               metrics: nil
                                                 views: views
        ]
       ];

    [self.view addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];

    [self.view  setNeedsUpdateConstraints];
}

-(id)getExistingViewOfClass:(Class)class inContainer:(UIView *)container
{
    for (id view in container.subviews) {
        if ([view isMemberOfClass:class]) return view;
    }
    return nil;
}

@end
