#import "UIViewController+WMFArticlePresentation.h"
#import "Wikipedia-Swift.h"

#import "MWKDataStore.h"
#import "WMFArticleDataStore.h"

#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"

#import "PiwikTracker+WMFExtensions.h"
#import "WMFArticleViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFArticlePresentation)

- (WMFArticleViewController *)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore previewStore:(WMFArticleDataStore *)previewStore restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated {
    if (!restoreScrollPosition) {
        url = [url wmf_URLWithFragment:nil];
    }

    WMFArticleViewController *vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:dataStore previewStore:previewStore];
    [self wmf_pushArticleViewController:vc animated:animated];
    return vc;
}

- (void)wmf_pushArticleWithURL:(NSURL *)url dataStore:(MWKDataStore *)dataStore previewStore:(WMFArticleDataStore *)previewStore animated:(BOOL)animated {
    [self wmf_pushArticleWithURL:url dataStore:dataStore previewStore:previewStore restoreScrollPosition:NO animated:animated];
}

- (void)wmf_pushArticleViewController:(WMFArticleViewController *)viewController animated:(BOOL)animated {
    if (self.navigationController != nil) {
        [self.navigationController pushViewController:viewController animated:animated];
    } else if ([[self.childViewControllers firstObject] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)[self.childViewControllers firstObject];
        UINavigationController *nav = [tab selectedViewController];
        [nav pushViewController:viewController animated:animated];
    } else {
        NSAssert(0, @"Unexpected view controller hierarchy");
    }
    [[PiwikTracker sharedInstance] wmf_logView:viewController];

    if (viewController.isAddingArticleToHistoryListEnabled) {
        // Use slight delay so history interface doesn't try to re-order items during push animation when you select item from history.
        dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
            MWKHistoryList *historyList = viewController.dataStore.historyList;
            [historyList addPageToHistoryWithURL:viewController.articleURL];
        });
    }
}

- (void)wmf_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.navigationController != nil) {
        [self.navigationController pushViewController:viewController animated:animated];
    } else if ([[self.childViewControllers firstObject] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)[self.childViewControllers firstObject];
        UINavigationController *nav = [tab selectedViewController];
        [nav pushViewController:viewController animated:animated];
    } else {
        NSAssert(0, @"Unexpected view controller hierarchy");
    }
}

@end

NS_ASSUME_NONNULL_END
