#import <UIKit/UIKit.h>

@class MASConstraintMaker;

@interface UIViewController (WMF_ChildViewController)

- (void)wmf_addChildController:(UIViewController*)childController
             withContainerView:(UIView*)containerView
                   constraints:(void (^)(MASConstraintMaker* makeChildControllerView))constraintsMaker;

- (void)wmf_addChildController:(UIViewController*)childController andConstrainToEdgesOfContainerView:(UIView*)containerView;

@end
