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

    WMFArticleViewController *articleVC = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:dataStore theme:theme];
    articleVC.articleLoadCompletion = articleLoadCompletion;
    
    ResolveDestinationContainerViewController *resolveDestinationContainerVC = [[ResolveDestinationContainerViewController alloc] initWithDataStore:dataStore theme:theme delegate:(id<ResolveDestinationContainerDelegate>)articleVC url:url embedOnAppearance:YES];
    articleVC.resolveDestinationContainerVC = resolveDestinationContainerVC;
    [self wmf_pushViewController:resolveDestinationContainerVC animated:animated];
    return articleVC;
}

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme animated:(BOOL)animated {
    
    url = [url wmf_URLWithFragment:nil];
    WMFArticleViewController *articleVC = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:dataStore theme:theme];
    
    //todo: this ResolveDestinationContainerDelegate cast does not seem ideal.
    ResolveDestinationContainerViewController *resolveDestinationContainerVC = [[ResolveDestinationContainerViewController alloc] initWithDataStore:dataStore theme:theme delegate:(id<ResolveDestinationContainerDelegate>)articleVC url:url embedOnAppearance:YES];
    articleVC.resolveDestinationContainerVC = resolveDestinationContainerVC;
    [self wmf_pushViewController:resolveDestinationContainerVC animated:animated];
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
    } else if ([self isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController *)self pushViewController:viewController animated:animated];
    }
}

- (void)wmf_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.navigationController != nil) {
        [self.navigationController pushViewController:viewController animated:animated];
    } else if (self.presentingViewController != nil) {
        UIViewController *presentingViewController = self.presentingViewController;
        [presentingViewController dismissViewControllerAnimated:YES
                                                     completion:^{
                                                         [presentingViewController wmf_pushViewController:viewController animated:animated];
                                                     }];
    } else if (self.parentViewController != nil) {
        [self.parentViewController wmf_pushViewController:viewController animated:animated];
    } else if ([self isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController *)self pushViewController:viewController animated:animated];
    }
}

@end

NS_ASSUME_NONNULL_END
