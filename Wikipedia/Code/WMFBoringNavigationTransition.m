

#import "WMFBoringNavigationTransition.h"

@implementation WMFBoringNavigationTransition

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext;
{
    return 0.35;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext;
{
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    __block UIViewController* toViewController   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect screenFrame                   = fromViewController.view.frame;
    UIView* containerView                = [transitionContext containerView];
    [containerView addSubview:toViewController.view];
    
    CGFloat startX;
    CGFloat endX;
    if (self.operation == UINavigationControllerOperationPush) {
        startX = screenFrame.size.width;
        endX   = -screenFrame.size.width;
    } else {
        startX = -screenFrame.size.width;
        endX   = screenFrame.size.width;
    }

    CGRect f = toViewController.view.frame;
    f.origin.x = startX;
    toViewController.view.frame = f;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^
    {
        toViewController.view.frame = CGRectOffset(toViewController.view.frame, -startX, 0);
        fromViewController.view.frame = CGRectOffset(screenFrame, endX, 0);
    }                completion:^(BOOL finished) {
        toViewController = toViewController;
        [fromViewController.view removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}
@end
