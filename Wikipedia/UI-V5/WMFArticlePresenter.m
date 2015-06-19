
#import "WMFArticlePresenter.h"
#import "WebViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"

@implementation WMFArticlePresenter

+ (WMFArticlePresenter*)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (UIViewController*)root {
    return (UIViewController*)[[UIApplication sharedApplication] delegate].window.rootViewController;
}

- (void)presentWebViewControllerThenPerformBlock:(void (^)(WebViewController*))block {
    WebViewController* webVC = (WebViewController*)[WMFArticlePresenter popToFirstViewControllerOfClass:[WebViewController class]];
    if (webVC) {
        if (block) {
            block(webVC);
        }
    } else {
        webVC = [WebViewController wmf_initialViewControllerFromClassStoryboard];
        UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:webVC];
        [[WMFArticlePresenter root] presentViewController:nc animated:YES completion:^{
            if (block) {
                block(webVC);
            }
        }];
    }
}

- (void)presentArticleWithTitle:(MWKTitle*)title
                discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                           then:(void (^)())block {
    [self presentWebViewControllerThenPerformBlock:^(WebViewController* webVC){
        [webVC navigateToPage:title discoveryMethod:discoveryMethod];
        if (block) {
            block();
        }
    }];
}

- (void)presentRandomArticleThen:(void (^)())block {
    [self presentWebViewControllerThenPerformBlock:^(WebViewController* webVC){
        [webVC loadRandomArticle];
        if (block) {
            block();
        }
    }];
}

- (void)presentTodaysArticleThen:(void (^)())block {
    [self presentWebViewControllerThenPerformBlock:^(WebViewController* webVC){
        [webVC loadTodaysArticle];
        if (block) {
            block();
        }
    }];
}

- (void)presentWebViewThen:(void (^)())block {
    [self presentWebViewControllerThenPerformBlock:^(WebViewController* webVC){
        if (block) {
            block();
        }
    }];
}

- (void)loadTodaysArticle {
    WebViewController* webVC = (WebViewController*)[WMFArticlePresenter firstViewControllerOnNavStackOfClass:[WebViewController class]];
    [webVC loadTodaysArticle];
}

// Pop to and return first view controller of class found. Returns nil if no view controller of class found.
+ (UIViewController*)popToFirstViewControllerOfClass:(Class)class {
    UIViewController* vc = [self firstViewControllerOnNavStackOfClass:class];
    if (vc) {
        // Dismiss any view controllers presented by the vc.
        if (vc.presentedViewController) {
            [vc dismissViewControllerAnimated:YES completion:nil];
        }
        if ([vc.presentingViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController* navVC = (UINavigationController*)vc.presentingViewController;

            // Pop vc to top of navigation controller stack.
            [navVC popToViewController:vc animated:NO];

            // Dismiss any view controllers presented by the vc's navigation controller.
            if (navVC.presentedViewController) {
                [navVC dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
    return vc;
}

// Return first view controller of class found anywhere on nav stack. Return nil if not found.
+ (UIViewController*)firstViewControllerOnNavStackOfClass:(Class)class {
    UIViewController* soughtVC = nil;
    UIViewController* thisVC   = [self root];
    while ((thisVC = thisVC.presentedViewController)) {
        if ([thisVC isKindOfClass:class]) {
            soughtVC = thisVC;
            break;
        } else if ([thisVC isKindOfClass:[UINavigationController class]]) {
            soughtVC = [self firstViewControllerOfClass:class shownByNavigationController:(UINavigationController*)thisVC];
            if (soughtVC) {
                break;
            }
        }
    }
    return soughtVC;
}

// Return first view controller of class found in navigation controller's view controllers. Return nil if not found.
+ (UIViewController*)firstViewControllerOfClass:(Class)class shownByNavigationController:(UINavigationController*)navController {
    NSPredicate* p    = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@", class];
    NSArray* filtered = [navController.viewControllers filteredArrayUsingPredicate:p];
    return (filtered.count == 0) ? nil : filtered.firstObject;
}

@end
