
#import "WMFArticlePresenter.h"
#import "WMFWebViewController.h"
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

// Ensures the web view is foremost. Adds web view to nav stack if none found. Returns web view controller.
- (WMFWebViewController*)presentWebViewController {
    WMFWebViewController* webVC = (WMFWebViewController*)[WMFArticlePresenter popToFirstViewControllerOfClass:[WMFWebViewController class]];
    if (!webVC) {
        webVC = [WMFWebViewController wmf_initialViewControllerFromClassStoryboard];
        UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:webVC];
        [[WMFArticlePresenter root] presentViewController:nc animated:YES completion:nil];
    }
    return webVC;
}

- (void)presentCurrentArticle {
    [self presentWebViewController];
}

- (void)presentRandomArticle {
    [[self presentWebViewController] loadRandomArticle];
}

- (void)presentTodaysArticle {
    [[self presentWebViewController] loadTodaysArticle];
}

- (void)presentArticleWithTitle:(MWKTitle*)title
                discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    [[self presentWebViewController] navigateToPage:title discoveryMethod:discoveryMethod];
}

- (void)loadTodaysArticle {
    WMFWebViewController* webVC = (WMFWebViewController*)[WMFArticlePresenter firstViewControllerOnNavStackOfClass:[WMFWebViewController class]];
    [webVC loadTodaysArticle];
}

- (void)reloadCurrentArticleFromNetwork {
    WMFWebViewController* webVC = (WMFWebViewController*)[WMFArticlePresenter firstViewControllerOnNavStackOfClass:[WMFWebViewController class]];
    [webVC reloadCurrentArticleFromNetwork];
}

// Pop to and return first view controller of class found. Returns nil if no view controller of class found.
+ (UIViewController*)popToFirstViewControllerOfClass:(Class)class {
    UIViewController* vc = [self firstViewControllerOnNavStackOfClass:class];
    if (vc) {
        // Dismiss any view controllers presented by the vc.
        if (vc.presentedViewController) {
            [vc dismissViewControllerAnimated:YES completion:nil];
        }
        if (vc.navigationController) {
            // Pop vc to top of navigation controller stack.
            [vc.navigationController popToViewController:vc animated:YES];
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
