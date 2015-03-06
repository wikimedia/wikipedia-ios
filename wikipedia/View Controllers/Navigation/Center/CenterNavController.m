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

@interface CenterNavController ()

@property (strong, nonatomic) NSString* wikipediaZeroLearnMoreExternalUrl;

@end

@implementation CenterNavController

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

#pragma mark Article

- (void)loadArticleWithTitle:(MWKTitle*)title
                    animated:(BOOL)animated
             discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                  popToWebVC:(BOOL)popToWebVC {
    WebViewController* webVC = [self searchNavStackForViewControllerOfClass:[WebViewController class]];
    if (webVC) {
        MWKArticle* article = [[SessionSingleton sharedInstance].dataStore articleWithTitle:title];
        [SessionSingleton sharedInstance].currentArticle = article;

        [webVC navigateToPage:title
              discoveryMethod:discoveryMethod
         showLoadingIndicator:YES];
        if (popToWebVC) {
            [ROOT popToViewController:webVC animated:animated];
        }
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
    MWKTitle* pageTitle = [[SessionSingleton sharedInstance] mainArticleTitle];
    [self loadArticleWithTitle:pageTitle
                      animated:YES
               discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH
                    popToWebVC:NO];
}

- (void)loadTodaysArticleIfNoCoreDataForCurrentArticle {
    [self loadTodaysArticle];
}

- (void)loadRandomArticle {
    [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];

    (void)[[RandomArticleFetcher alloc] initAndFetchRandomArticleForDomain:[SessionSingleton sharedInstance].currentArticleSite.language
                                                               withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                        thenNotifyDelegate:self];
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
                               discoveryMethod:MWK_DISCOVERY_METHOD_RANDOM
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

    MWKTitle* pageTitle = [[SessionSingleton sharedInstance] mainArticleTitleForSite:[SessionSingleton sharedInstance].searchSite languageCode:languageId];

    [self loadArticleWithTitle:pageTitle
                      animated:YES
               discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH
                    popToWebVC:NO];
}

@end
