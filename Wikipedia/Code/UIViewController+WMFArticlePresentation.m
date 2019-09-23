#import "UIViewController+WMFArticlePresentation.h"
@import WMF;
#import "Wikipedia-Swift.h"
#import "WMFArticleViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFArticlePresentation)

- (NSNumber *)embedTypeNumber {
    //NSInteger embedTypeInt =  [self conformsToProtocol:@protocol(WMFImageScaleTransitionProviding)] ? LoadingFlowControllerEmbedTypeImmediately : LoadingFlowControllerEmbedTypeAfterFetch;
    NSInteger embedTypeInt = LoadingFlowControllerEmbedTypeImmediately;
    return [NSNumber numberWithInteger:embedTypeInt];
}

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

    LoadingFlowController *loadingFlowController = [[LoadingFlowController alloc] initWithArticleViewController:articleVC embedTypeNumber: [self embedTypeNumber]];
    [self wmf_pushViewController:loadingFlowController animated:animated];
    return articleVC;
}

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme animated:(BOOL)animated {
    
    url = [url wmf_URLWithFragment:nil];
    WMFArticleViewController *articleVC = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:dataStore theme:theme];
    LoadingFlowController *loadingFlowController = [[LoadingFlowController alloc] initWithArticleViewController:articleVC embedTypeNumber: [self embedTypeNumber]];
    
    [self wmf_pushViewController:loadingFlowController animated:animated];
}

- (void)wmf_pushArticleViewController:(WMFArticleViewController *)viewController animated:(BOOL)animated {

    if (self.parentViewController != nil && self.parentViewController.navigationController) {
        [self.parentViewController wmf_pushArticleViewController:viewController animated:animated];
        return;
    }
    
    //embed in LoadingFlowController first

    LoadingFlowController *loadingFlowController = [[LoadingFlowController alloc] initWithArticleViewController:viewController embedTypeNumber: [self embedTypeNumber]];
    
    if (self.presentingViewController != nil) {
        UIViewController *presentingViewController = self.presentingViewController;
        [presentingViewController dismissViewControllerAnimated:YES
                                                     completion:^{
                                                         [presentingViewController wmf_pushArticleViewController:viewController animated:animated];
                                                     }];
    } else if (self.navigationController != nil) {
        [self.navigationController pushViewController:loadingFlowController animated:animated];
    } else if ([self isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController *)self pushViewController:loadingFlowController animated:animated];
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
