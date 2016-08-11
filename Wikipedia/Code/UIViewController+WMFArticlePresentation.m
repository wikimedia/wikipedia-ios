
#import "UIViewController+WMFArticlePresentation.h"
#import "UIColor+WMFHexColor.h"
#import "Wikipedia-Swift.h"

#import "MWKDataStore.h"
#import "MWKUserDataStore.h"

#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"

#import <BlocksKit/BlocksKit+UIKit.h>

#import "PiwikTracker+WMFExtensions.h"
#import "WMFArticleViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (WMFArticlePresentation)

- (void)wmf_pushArticleWithURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated {
    if (!restoreScrollPosition) {
        url = [url wmf_URLWithFragment:nil];
    }

    WMFArticleViewController* vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:dataStore];
    [self wmf_pushArticleViewController:vc animated:animated];
}

- (void)wmf_pushArticleWithURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore animated:(BOOL)animated {
    [self wmf_pushArticleWithURL:url dataStore:dataStore restoreScrollPosition:NO animated:animated];
}

- (void)wmf_pushArticleViewController:(WMFArticleViewController*)viewController animated:(BOOL)animated {
    if (self.navigationController != nil) {
        [self.navigationController pushViewController:viewController animated:animated];
    } else if ([[self.childViewControllers firstObject] isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tab     = (UITabBarController*)[self.childViewControllers firstObject];
        UINavigationController* nav = [tab selectedViewController];
        [nav pushViewController:viewController animated:animated];
    } else {
        NSAssert(0, @"Unexpected view controller hierarchy");
    }
    [[PiwikTracker wmf_configuredInstance] wmf_logView:viewController];

    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        MWKHistoryList* historyList = viewController.dataStore.userDataStore.historyList;
        [historyList addPageToHistoryWithURL:viewController.articleURL];
    });
}

- (void)wmf_pushViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if (self.navigationController != nil) {
        [self.navigationController pushViewController:viewController animated:animated];
    } else if ([[self.childViewControllers firstObject] isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tab     = (UITabBarController*)[self.childViewControllers firstObject];
        UINavigationController* nav = [tab selectedViewController];
        [nav pushViewController:viewController animated:animated];
    } else {
        NSAssert(0, @"Unexpected view controller hierarchy");
    }
}

@end




NS_ASSUME_NONNULL_END