#import "WMFArticleNavigationController.h"
#import <objc/runtime.h>
@import WMF.WMFLocalization;

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
    self.readingListHintHidden = YES;

    static UIImage *clearImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContext(CGSizeMake(1, 1));
        CGContextRef context = UIGraphicsGetCurrentContext();
        [[UIColor clearColor] setFill];
        CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
        clearImage = UIGraphicsGetImageFromCurrentImageContext();
    });

    [self.secondToolbar setBackgroundImage:clearImage forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    self.secondToolbar.clipsToBounds = YES;

    [self.view addSubview:self.secondToolbar];
    [self layoutSecondToolbarForViewBounds:self.view.bounds hidden:self.isSecondToolbarHidden animated:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate {
    self.navigationDelegate = delegate;
}

#pragma mark - Hint

- (void)setReadingListHintHidden:(BOOL)readingListHintHidden {
    _readingListHintHidden = readingListHintHidden;
    [self layoutSecondToolbarForViewBounds:self.view.bounds hidden:self.isSecondToolbarHidden animated:YES];
}

- (void)setReadingListHintHeight:(CGFloat)readingListHintHeight {
    _readingListHintHeight = readingListHintHeight;
    [self layoutSecondToolbarForViewBounds:self.view.bounds hidden:self.isSecondToolbarHidden animated:YES];
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
            if (self.readingListHintHidden) {
                origin = CGPointMake(0, self.toolbar.frame.origin.y - size.height);
            } else {
                origin = CGPointMake(0, self.toolbar.frame.origin.y - size.height - self.readingListHintHeight);
            }
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
    [self.secondToolbar setItems:newItems animated:animated];
    if (newItems.count > 0) {
        [self setSecondToolbarHidden:NO animated:YES];
    } else {
        [self setSecondToolbarHidden:YES animated:YES];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self.navigationDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.navigationDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
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
