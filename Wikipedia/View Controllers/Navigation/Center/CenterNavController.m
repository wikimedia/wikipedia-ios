//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CenterNavController.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"
#import "UINavigationController+SearchNavStack.h"
#import "SessionSingleton.h"
#import "WebViewController.h"
#import "SectionEditorViewController.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "TopMenuContainerView.h"
#import "QueuesSingleton.h"
#import "RandomArticleFetcher.h"
#import "MWKSiteInfo.h"
#import "MWKSiteInfoFetcher.h"
#import "UIViewController+ModalPresent.h"
#import "LanguagesViewController.h"
#import "UIViewController+ModalPop.h"
#import "UIViewController+Alert.h"
#import "QueuesSingleton.h"

@interface CenterNavController ()
<LanguageSelectionDelegate>
@property (strong, nonatomic) NSString* wikipediaZeroLearnMoreExternalUrl;

@property (readonly, strong, nonatomic) MWKSiteInfoFetcher* siteInfoFetcher;

@end

@implementation CenterNavController
@synthesize siteInfoFetcher = _siteInfoFetcher;

- (MWKSiteInfoFetcher*)siteInfoFetcher {
    if (!_siteInfoFetcher) {
        _siteInfoFetcher = [MWKSiteInfoFetcher new];
        /*
           HAX: Force this particular site info fetcher to share the article operation queue. This allows for the
           cancellation of site info requests when going to the main page, e.g. when clicking a link after clicking
           "Today" in the main menu.

           This is done here and not for all site info fetchers to prevent unintended side effects.
         */
        _siteInfoFetcher.requestManager.operationQueue =
            [[[QueuesSingleton sharedInstance] articleFetchManager] operationQueue];
    }
    return _siteInfoFetcher;
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.delegate = self;

    self.isTransitioningBetweenViewControllers = NO;
}

- (void)navigationController:(UINavigationController*)navigationController
      willShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated {
    // The root VC isn't presented with any of the overridden push/pop methods which call
    // "animateStatusBarHeightChangesForViewController", so just for the root vc set topMenuHidden
    // here.
    static BOOL firstTimeSoRootVC = YES;
    if (firstTimeSoRootVC) {
        ROOT.topMenuHidden = [ROOT shouldHideTopNavIfNecessaryForViewController:viewController];
    }
    firstTimeSoRootVC = NO;

    self.isTransitioningBetweenViewControllers = YES;
}

- (void)navigationController:(UINavigationController*)navigationController
       didShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated {
    self.isTransitioningBetweenViewControllers = NO;
}

- (void)setIsTransitioningBetweenViewControllers:(BOOL)isTransitioningBetweenViewControllers {
    _isTransitioningBetweenViewControllers = isTransitioningBetweenViewControllers;

    // Disabling userInteractionEnabled when nav stack views are being pushed/popped prevents
    // "nested push animation can result in corrupted navigation bar" and "unbalanced calls
    // to begin/end appearance transitions" errors. If this line is commented out, you can
    // trigger the error by rapidly tapping on the main menu toggle (the "W" icon presently).
    // You can also trigger another error by tapping the edit pencil, then tap the "X" icon
    // then very quickly tap the "W" icon.
    self.view.userInteractionEnabled = !isTransitioningBetweenViewControllers;
}

- (WebViewController*)webViewController {
    return [self searchNavStackForViewControllerOfClass:[WebViewController class]];
}

#pragma mark Article

- (void)loadArticleWithTitle:(MWKTitle*)title
                    animated:(BOOL)animated
             discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                  popToWebVC:(BOOL)popToWebVC {
    WebViewController* webVC = [self webViewController];
    NSParameterAssert(webVC);
    MWKArticle* article = [[SessionSingleton sharedInstance].dataStore articleWithTitle:title];
    [SessionSingleton sharedInstance].currentArticle = article;

    [webVC navigateToPage:title
          discoveryMethod:discoveryMethod];
    if (popToWebVC) {
        [ROOT popToViewController:webVC animated:animated];
    }
}

#pragma mark Is editing

- (BOOL)isEditorOnNavstack {
    id editVC = [self searchNavStackForViewControllerOfClass:[SectionEditorViewController class]];
    return editVC ? YES : NO;
}

- (SectionEditorViewController*)editor {
    id editVC = [self searchNavStackForViewControllerOfClass:[SectionEditorViewController class]];
    return editVC;
}

#pragma Wikipedia Zero alert dialogs

- (void)promptFirstTimeZeroOnWithTitleIfAppropriate:(NSString*)title {
    if (![SessionSingleton sharedInstance].zeroConfigState.zeroOnDialogShownOnce) {
        [[SessionSingleton sharedInstance].zeroConfigState setZeroOnDialogShownOnce];
        self.wikipediaZeroLearnMoreExternalUrl = MWLocalizedString(@"zero-webpage-url", nil);
        UIAlertView* dialog = [[UIAlertView alloc]
                               initWithTitle:title
                                         message:MWLocalizedString(@"zero-learn-more", nil)
                                        delegate:self
                               cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                               otherButtonTitles:MWLocalizedString(@"zero-learn-more-learn-more", nil)
                               , nil];
        [dialog show];
    }
}

- (void)promptZeroOff {
    UIAlertView* dialog = [[UIAlertView alloc]
                           initWithTitle:MWLocalizedString(@"zero-charged-verbiage", nil)
                                     message:MWLocalizedString(@"zero-charged-verbiage-extended", nil)
                                    delegate:self
                           cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                           otherButtonTitles:nil
                           , nil];
    [dialog show];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (1 == buttonIndex) {
        NSURL* url = [NSURL URLWithString:self.wikipediaZeroLearnMoreExternalUrl];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (BOOL)isTopViewControllerAWebviewController {
    return [[self topViewController] isMemberOfClass:[WebViewController class]];
}

- (void)loadTodaysArticle {
    [self.siteInfoFetcher fetchInfoForSite:[[SessionSingleton sharedInstance] searchSite]
                                   success:^(MWKSiteInfo* siteInfo) {
        [self loadArticleWithTitle:siteInfo.mainPageTitle
                          animated:YES
                   discoveryMethod:MWKHistoryDiscoveryMethodSearch
                        popToWebVC:NO];
    }
                                   failure:^(NSError* error) {
        if ([error.domain isEqual:NSURLErrorDomain]
            && error.code == NSURLErrorCannotFindHost) {
            [self showLanguages];
        } else {
            [[self webViewController] showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:2.0];
        }
    }];
}

- (void)loadRandomArticle {
    [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];

    (void)[[RandomArticleFetcher alloc] initAndFetchRandomArticleForDomain:[SessionSingleton sharedInstance].currentArticleSite.language
                                                               withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                        thenNotifyDelegate:self];
}

- (void)showLanguages {
    [self performModalSequeWithID:@"modal_segue_show_languages"
                  transitionStyle:UIModalTransitionStyleCoverVertical
                            block:^(LanguagesViewController* languagesVC) {
        languagesVC.languageSelectionDelegate = self;
    }];
}

- (void)languageSelected:(NSDictionary*)langData sender:(LanguagesViewController*)sender {
    [NAV switchPreferredLanguageToId:langData[@"code"]];
    [self popModalToRoot];
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if ([sender isKindOfClass:[RandomArticleFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                NSString* title = (NSString*)fetchedData;
                if (title) {
                    MWKTitle* pageTitle = [[SessionSingleton sharedInstance].currentArticleSite titleWithString:title];
                    [self loadArticleWithTitle:pageTitle
                                      animated:YES
                               discoveryMethod:MWKHistoryDiscoveryMethodRandom
                                    popToWebVC:NO]; // Don't pop - popModal has already been called.
                }
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
                break;
            case FETCH_FINAL_STATUS_FAILED:
                //[self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    }
}

- (void)switchPreferredLanguageToId:(NSString*)languageId {
    [[SessionSingleton sharedInstance] setSearchLanguage:languageId];
    [self loadTodaysArticle];
}

@end
