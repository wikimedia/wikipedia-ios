#import "UIViewController+WMFArticlePresentation.h"
@import WMF;
#import "Wikipedia-Swift.h"
#import "WMFArticleViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFArticlePresentation)

- (WMFArticleViewController *)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated {
    return [self wmf_pushArticleWithURL:url
                              dataStore:dataStore
                                  theme:theme
                  restoreScrollPosition:restoreScrollPosition
                               animated:animated
                  articleLoadCompletion:^{
                  }];
}

- (WMFArticleViewController *)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated articleLoadCompletion:(dispatch_block_t)articleLoadCompletion {
    if (!restoreScrollPosition) {
        url = [url wmf_URLWithFragment:nil];
    }

    WMFArticleViewController *vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:dataStore theme:theme];
    vc.articleLoadCompletion = articleLoadCompletion;
    [self wmf_pushArticleViewController:vc animated:animated];
    return vc;
}

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme animated:(BOOL)animated {
    [self wmf_pushArticleWithURL:url dataStore:dataStore theme:theme restoreScrollPosition:NO animated:animated];
}

- (void)wmf_pushArticleViewController:(WMFArticleViewController *)viewController animated:(BOOL)animated {
    if (self.parentViewController != nil && self.parentViewController.navigationController) {
        [self.parentViewController wmf_pushArticleViewController:viewController animated:animated];
    } else if (self.presentingViewController != nil) {
        UIViewController *presentingViewController = self.presentingViewController;
        [presentingViewController dismissViewControllerAnimated:YES
                                                     completion:^{
                                                         [presentingViewController wmf_pushArticleViewController:viewController animated:animated];
                                                     }];
    } else if (self.navigationController != nil) {
        [self.navigationController pushViewController:viewController animated:animated];
    } else if ([[self.childViewControllers firstObject] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)[self.childViewControllers firstObject];
        UINavigationController *nav = [tab selectedViewController];
        [nav pushViewController:viewController animated:animated];
    } else {
        NSAssert(false, @"Unexpected view controller hierarchy");
    }
}

- (void)wmf_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.navigationController != nil) {
        [self.navigationController pushViewController:viewController animated:animated];
    } else if ([[self.childViewControllers firstObject] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)[self.childViewControllers firstObject];
        UINavigationController *nav = [tab selectedViewController];
        [nav pushViewController:viewController animated:animated];
    } else if (self.presentingViewController != nil) {
        UIViewController *presentingViewController = self.presentingViewController;
        [presentingViewController dismissViewControllerAnimated:YES
                                                     completion:^{
                                                         [presentingViewController wmf_pushViewController:viewController animated:animated];
                                                     }];
    } else if (self.parentViewController != nil) {
        [self.parentViewController wmf_pushViewController:viewController animated:animated];
    } else {
        NSAssert(0, @"Unexpected view controller hierarchy");
    }
}

@end

NS_ASSUME_NONNULL_END
