#import "WMFArticleNavigationController.h"
#import <objc/runtime.h>

static const NSTimeInterval WMFArticleNavigationControllerSecondToolbarAnimationDuration = 0.3;

@interface WMFArticleNavigationController () <UINavigationControllerDelegate>

@property (nullable, nonatomic, weak) id<UINavigationControllerDelegate> navigationDelegate;

@property (nonatomic, strong) UIToolbar *secondToolbar;
@property (nonatomic, getter=isSecondToolbarHidden) BOOL secondToolbarHidden;

@end

@implementation WMFArticleNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [super setDelegate:self];

    self.secondToolbarHidden = YES;
    self.secondToolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.secondToolbar];
    [self layoutSecondToolbarForViewBounds:self.view.bounds hidden:self.isSecondToolbarHidden animated:NO];
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate {
    self.navigationDelegate = delegate;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutSecondToolbarForViewBounds:self.view.bounds hidden:self.isSecondToolbarHidden animated:NO];
}

- (void)layoutSecondToolbarForViewBounds:(CGRect)bounds hidden:(BOOL)hidden animated:(BOOL)animated {
    CGSize size = CGSizeMake(bounds.size.width, 60);
    CGPoint origin;
    if (hidden) {
        if (self.isToolbarHidden) {
            origin = CGPointMake(0, bounds.size.height);
        } else {
            origin = CGPointMake(0, self.toolbar.frame.origin.y);
        }
    } else {
        if (self.isToolbarHidden) {
            origin = CGPointMake(0, bounds.size.height - size.height);
        } else {
            origin = CGPointMake(0, self.toolbar.frame.origin.y - size.height);
        }
    }
    dispatch_block_t animations = ^{
        self.secondToolbar.alpha = hidden ? 0 : 1;
        self.secondToolbar.frame = (CGRect){origin, size};
    };
    if (animated) {
        [UIView animateWithDuration:WMFArticleNavigationControllerSecondToolbarAnimationDuration animations:animations];
    } else {
        animations();
    }
}

- (void)setSecondToolbarHidden:(BOOL)secondToolbarHidden animated:(BOOL)animated {
    self.secondToolbarHidden = secondToolbarHidden;
    [self layoutSecondToolbarForViewBounds:self.view.bounds hidden:secondToolbarHidden animated:animated];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [self.navigationDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
    }
    //Ideally this observes secondToolbarItems for changes, but this is all we need for our use case at the moment
    NSArray *newItems = viewController.secondToolbarItems;
    self.toolbarItems = newItems;
    if (newItems.count > 0) {
        [self setSecondToolbarHidden:NO animated:NO];
    } else {
        [self setSecondToolbarHidden:YES animated:NO];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.navigationDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationControllerSupportedInterfaceOrientations:)]) {
        return [self.navigationDelegate navigationControllerSupportedInterfaceOrientations:navigationController];
    } else {
        return self.supportedInterfaceOrientations;
    }
}

- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationControllerPreferredInterfaceOrientationForPresentation:)]) {
        return [self.navigationDelegate navigationControllerPreferredInterfaceOrientationForPresentation:navigationController];
    } else {
        return self.preferredInterfaceOrientationForPresentation;
    }
}

- (nullable id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                                  interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:interactionControllerForAnimationController:)]) {
        return [self.navigationDelegate navigationController:navigationController interactionControllerForAnimationController:animationController];
    } else {
        return nil;
    }
}

- (nullable id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                           animationControllerForOperation:(UINavigationControllerOperation)operation
                                                        fromViewController:(UIViewController *)fromVC
                                                          toViewController:(UIViewController *)toVC {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:animationControllerForOperation:fromViewController:toViewController:)]) {
        return [self.navigationDelegate navigationController:navigationController animationControllerForOperation:operation fromViewController:fromVC toViewController:toVC];
    } else {
        return nil;
    }
}

@end

@implementation UIViewController (UINavigationControllerContextualSecondToolbarItems)

static const void *SecondToolbarItemsKey = &SecondToolbarItemsKey;

- (void)setSecondToolbarItems:(NSArray<__kindof UIBarButtonItem *> *)secondToolbarItems {
    objc_setAssociatedObject(self, SecondToolbarItemsKey, secondToolbarItems, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSArray<__kindof UIBarButtonItem *> *)secondToolbarItems {
    return objc_getAssociatedObject(self, SecondToolbarItemsKey);
}

@end
