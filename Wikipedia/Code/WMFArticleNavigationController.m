#import "WMFArticleNavigationController.h"

@interface WMFArticleNavigationController () <UINavigationControllerDelegate>

@property(nullable, nonatomic, weak) id<UINavigationControllerDelegate> navigationDelegate;

@end

@implementation WMFArticleNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [super setDelegate:self];
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate {
    self.navigationDelegate = delegate;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController*)navigationController willShowViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [self.navigationDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
    }
}

- (void)navigationController:(UINavigationController*)navigationController didShowViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.navigationDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController*)navigationController {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationControllerSupportedInterfaceOrientations:)]) {
        return [self.navigationDelegate navigationControllerSupportedInterfaceOrientations:navigationController];
    } else {
        return self.supportedInterfaceOrientations;
    }
}

- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController*)navigationController {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationControllerPreferredInterfaceOrientationForPresentation:)]) {
        return [self.navigationDelegate navigationControllerPreferredInterfaceOrientationForPresentation:navigationController];
    } else {
        return self.preferredInterfaceOrientationForPresentation;
    }
}

- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController*)navigationController
                                   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>)animationController {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:interactionControllerForAnimationController:)]) {
        return [self.navigationDelegate navigationController:navigationController interactionControllerForAnimationController:animationController];
    } else {
        return nil;
    }
}

- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController*)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController*)fromVC
                                                           toViewController:(UIViewController*)toVC {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:animationControllerForOperation:fromViewController:toViewController:)]) {
        return [self.navigationDelegate navigationController:navigationController animationControllerForOperation:operation fromViewController:fromVC toViewController:toVC];
    } else {
        return nil;
    }
}

@end
