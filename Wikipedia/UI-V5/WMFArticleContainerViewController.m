#import "WMFArticleContainerViewController.h"

// Frameworks
#import <Masonry/Masonry.h>

// Controller
#import "WMFArticleViewController.h"
#import "WebViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"

// Model
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "MWKCitation.h"
#import "MWKTitle.h"

// View
#import "WMFArticlePopupTransition.h"

// Other
#import "SessionSingleton.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleContainerViewController ()
<WMFWebViewControllerDelegate, WMFArticleNavigationDelegate>
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong, readwrite) WMFArticleViewController* articleViewController;
@property (nonatomic, strong, readwrite) WebViewController* webViewController;

@property (nonatomic, weak) UIViewController<WMFArticleContentController>* currentArticleController;

@property (strong, nonatomic) WMFArticlePopupTransition* popupTransition;

@end

@implementation WMFArticleContainerViewController

+ (instancetype)articleContainerViewControllerWithDataStore:(MWKDataStore*)dataStore
                                                 savedPages:(MWKSavedPageList*)savedPages {
    return [[self alloc] initWithDataStore:dataStore savedPages:savedPages];
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages {
    self = [super init];
    if (self) {
        self.savedPageList = savedPages;
        self.dataStore     = dataStore;
        self.currentArticleController = self.articleViewController;
    }
    return self;
}

#pragma mark - Accessors

- (MWKArticle* __nullable)article {
    return self.currentArticleController.article;
}

- (void)setArticle:(MWKArticle* __nullable)article {
    if (WMF_EQUAL(self.article, isEqualToArticle:, article)) {
        return;
    }

    self.articleViewController.article = article;
    self.webViewController.article = article;
    self.title = article.title.text;
}

- (WMFArticleViewController*)articleViewController {
    if (!_articleViewController) {
        _articleViewController = [WMFArticleViewController articleViewControllerWithDataStore:self.dataStore
                                                                                   savedPages:self.savedPageList];
        _articleViewController.articleNavigationDelegate = self;
    }
    return _articleViewController;
}

- (WebViewController*)webViewController {
    if (!_webViewController) {
        _webViewController = [WebViewController wmf_initialViewControllerFromClassStoryboard];
        _webViewController.delegate = self;
    }
    return _webViewController;
}

- (void)setCurrentArticleController:(UIViewController<WMFArticleContentController>*)currentArticleController {
    [self setCurrentArticleController:currentArticleController animated:NO];
}

- (BOOL)isChildContentControllerViewInstalled:(UIViewController*)viewController {
    return [viewController isViewLoaded] && viewController.view.superview == self.view;
}

- (void)setCurrentArticleController:(UIViewController<WMFArticleContentController>*)currentArticleController
                           animated:(BOOL)animated {
    if (self.currentArticleController == currentArticleController
        && [self isChildContentControllerViewInstalled:currentArticleController]) {
        DDLogVerbose(@"Ignoring redundant set of currentArticleController");
        return;
    }

    if (currentArticleController.parentViewController != self) {
        [self addChildViewController:currentArticleController];
    }

    // prevent premature view loading
    if (![self isViewLoaded]) {
        [self primitiveSetCurrentArticleController:currentArticleController];
        return;
    }

    [self.view addSubview:currentArticleController.view];
    [currentArticleController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.left.right.top.and.bottom.equalTo(self.view);
    }];
    [currentArticleController.view layoutIfNeeded];

    void(^completion)(BOOL) = ^(BOOL finished) {
        NSParameterAssert(finished);
        // remove previous view from hierarchy
        if (currentArticleController != self.currentArticleController) {
            [self.currentArticleController.view removeFromSuperview];
        }
        [self primitiveSetCurrentArticleController:currentArticleController];
    };

    if (!self.currentArticleController || self.currentArticleController == _currentArticleController) {
        // no previous view, or installing view of current, no need to transition
        completion(YES);
        return;
    }

    currentArticleController.view.alpha = 0.f;
    [self transitionFromViewController:self.currentArticleController
                      toViewController:currentArticleController
                              duration:animated ? [CATransaction animationDuration] : 0.0
                               options:0
                            animations:^{
        currentArticleController.view.alpha = 1.0;
    }
                            completion:completion];
}

- (void)primitiveSetCurrentArticleController:(UIViewController<WMFArticleContentController>*)currentArticleController {
    _currentArticleController = currentArticleController;
    [_currentArticleController didMoveToParentViewController:self];
}

#pragma mark - ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentArticleController = self.articleViewController;
}

#pragma mark - WMFArticleNavigationDelegate

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender
      didTapCitationLink:(NSString* __nonnull)citationFragment {
    if (self.article.isCached) {
        [self showCitationWithFragment:citationFragment];
    } else {
//        if (!self.articleFetcherPromise) {
//            [self fetchArticle];
//        }
//        @weakify(self);
//        self.articleFetcherPromise.then(^(MWKArticle* _) {
//            @strongify(self);
//            [self showCitationWithFragment:citationFragment];
//        });
    }
}

- (void)showCitationWithFragment:(NSString*)fragment {
    NSParameterAssert(self.article.isCached);
    MWKCitation* tappedCitation = [self.article.citations bk_match:^BOOL (MWKCitation* citation) {
        return [citation.citationIdentifier isEqualToString:fragment];
    }];
    DDLogInfo(@"Tapped citation %@", tappedCitation);
//    if (!tappedCitation) {
//        DDLogWarn(@"Failed to parse citation for article %@", self.article);
    // TEMP: show webview until we figure out what to do w/ ReferencesVC
    [self.webViewController scrollToFragment:fragment];
    [self setCurrentArticleController:self.webViewController animated:YES];

//    }
}

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender
        didTapLinkToPage:(MWKTitle* __nonnull)title {
    [self presentPopupForTitle:title];
}

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender
      didTapExternalLink:(NSURL* __nonnull)externalURL {
    [[[SessionSingleton sharedInstance] zeroConfigState] showWarningIfNeededBeforeOpeningURL:externalURL];
}

#pragma mark - WMFArticleListItemController

- (WMFArticleControllerMode)mode {
    // TEMP: WebVC (and currentArticleController) will eventually conform to this
    return self.articleViewController.mode;
}

- (void)setMode:(WMFArticleControllerMode)mode animated:(BOOL)animated {
    // TEMP: WebVC (and currentArticleController) will eventually conform to this
    [self.articleViewController setMode:mode animated:animated];
}

#pragma mark - WMFWebViewControllerDelegate

- (void)webViewController:(WebViewController *)controller didTapOnLinkForTitle:(MWKTitle *)title {
    [self presentPopupForTitle:title];
}

#pragma mark - Popup

- (void)presentPopupForTitle:(MWKTitle*)title {
    MWKArticle* article                   = [self.dataStore articleWithTitle:title];
    WMFArticleContainerViewController* vc =
        [[WMFArticleContainerViewController alloc] initWithDataStore:self.dataStore
                                                          savedPages:self.savedPageList];
    vc.article = article;

    [self.navigationController pushViewController:vc animated:YES];

//    self.popupTransition =
//        [[WMFArticlePopupTransition alloc] initWithPresentingViewController:self
//                                                    presentedViewController:vc
//                                                          contentScrollView:nil];
//    self.popupTransition.nonInteractiveDuration = 0.5;
//    vc.transitioningDelegate                    = self.popupTransition;
//    vc.modalPresentationStyle                   = UIModalPresentationCustom;
//
//    [self presentViewController:vc animated:YES completion:NULL];
}

@end

NS_ASSUME_NONNULL_END
