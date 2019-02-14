#import "UIViewController+WMFArticlePresentation.h"
@import WMF;
#import "Wikipedia-Swift.h"
#import "WMFArticleViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFArticlePresentation)

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated {
    [self wmf_pushArticleWithURL:url
                       dataStore:dataStore
                           theme:theme
           restoreScrollPosition:restoreScrollPosition
                        animated:animated
                      completion:NULL];
}


- (void)wmf_checkAndPushPotentialArticleWithURL:(NSURL *)maybeArticleURL usingSession:(WMFSession *)session alertManager:(WMFAlertManager *)alertManager dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated completion:(nullable void (^)(WMFArticleViewController *_Nullable))completion {
    [session fetchSummaryForArticleURL:maybeArticleURL
                              priority:NSURLSessionTaskPriorityHigh
                     completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             dispatch_block_t bail = ^{
                                 [self wmf_openExternalUrl:maybeArticleURL];
                                 if (completion) {
                                     completion(nil);
                                 }
                             };
                             if (error) {
                                 [alertManager showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
                                 return;
                             }
                             NSDictionary *namespaceDictionary = result[@"namespace"];
                             if (![namespaceDictionary isKindOfClass:[NSDictionary class]]) {
                                 bail();
                                 return;
                             }
                             NSNumber *namespaceId = namespaceDictionary[@"id"];
                             if (![namespaceId isKindOfClass:[NSNumber class]]) {
                                 bail();
                                 return;
                             }
                             if ([namespaceId integerValue] != 0) {
                                 bail();
                                 return;
                             }
                             [self wmf_pushArticleWithURL:maybeArticleURL dataStore:dataStore theme:theme restoreScrollPosition:restoreScrollPosition animated:animated completion:completion];
                         });
                     }];
}

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore theme:(WMFTheme *)theme restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated completion:(nullable void (^)(WMFArticleViewController *_Nullable))completion {
    if (!restoreScrollPosition) {
        url = [url wmf_URLWithFragment:nil];
    }
    
    WMFArticleViewController *vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:dataStore theme:theme];
    vc.articleLoadCompletion = completion;
    [self wmf_pushArticleViewController:vc animated:animated];
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
