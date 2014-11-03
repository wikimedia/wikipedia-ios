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
#import "ArticleDataContextSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "QueuesSingleton.h"
#import "RandomArticleFetcher.h"

@interface CenterNavController ()

@property (strong, nonatomic) NSString *wikipediaZeroLearnMoreExternalUrl;

@end

@implementation CenterNavController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
 
    self.delegate = self;
    
    self.isTransitioningBetweenViewControllers = NO;
}

- (void)navigationController: (UINavigationController *)navigationController
      willShowViewController: (UIViewController *)viewController
                    animated: (BOOL)animated
{

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

- (void)navigationController: (UINavigationController *)navigationController
       didShowViewController: (UIViewController *)viewController
                    animated: (BOOL)animated
{
    self.isTransitioningBetweenViewControllers = NO;
}

-(void)setIsTransitioningBetweenViewControllers:(BOOL)isTransitioningBetweenViewControllers
{
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

-(void)loadArticleWithTitle: (MWKTitle *)title
                   animated: (BOOL)animated
            discoveryMethod: (MWKHistoryDiscoveryMethod)discoveryMethod
          invalidatingCache: (BOOL)invalidateCache
                 popToWebVC: (BOOL)popToWebVC
{
    WebViewController *webVC = [self searchNavStackForViewControllerOfClass:[WebViewController class]];
    if (webVC){
        [SessionSingleton sharedInstance].title = title;
        [webVC navigateToPage: title
              discoveryMethod: discoveryMethod
            invalidatingCache: invalidateCache
         showLoadingIndicator: YES];
        if (popToWebVC) {
            [ROOT popToViewController:webVC animated:animated];
        }
    }
}

#pragma mark Is editing

-(BOOL)isEditorOnNavstack
{
    id editVC = [self searchNavStackForViewControllerOfClass:[SectionEditorViewController class]];
    return editVC ? YES : NO;
}

-(SectionEditorViewController *)editor
{
    id editVC = [self searchNavStackForViewControllerOfClass:[SectionEditorViewController class]];
    return editVC;
}

#pragma Wikipedia Zero alert dialogs

-(void) promptFirstTimeZeroOnWithTitleIfAppropriate:(NSString *) title {
    if (![SessionSingleton sharedInstance].zeroConfigState.zeroOnDialogShownOnce) {
        [[SessionSingleton sharedInstance].zeroConfigState setZeroOnDialogShownOnce];
        self.wikipediaZeroLearnMoreExternalUrl = MWLocalizedString(@"zero-webpage-url", nil);
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle: title
                               message:MWLocalizedString(@"zero-learn-more", nil)
                               delegate:self
                               cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                               otherButtonTitles:MWLocalizedString(@"zero-learn-more-learn-more", nil)
                               , nil];
        [dialog show];
    }
}

-(void) promptZeroOff {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:MWLocalizedString(@"zero-charged-verbiage", nil)
                           message:MWLocalizedString(@"zero-charged-verbiage-extended", nil)
                           delegate:self
                           cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                           otherButtonTitles:nil
                           , nil];
    [dialog show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex) {
        NSURL *url = [NSURL URLWithString:self.wikipediaZeroLearnMoreExternalUrl];
        [[UIApplication sharedApplication] openURL:url];
    }
}

-(BOOL) isTopViewControllerAWebviewController
{
    return [[self topViewController] isMemberOfClass:[WebViewController class]];
}

-(void)loadTodaysArticle
{
    NSString *mainArticleTitle = [SessionSingleton sharedInstance].domainMainArticleTitle;
    if (mainArticleTitle) {
        MWKTitle *pageTitle = [[SessionSingleton sharedInstance].site titleWithString:mainArticleTitle];
        // Invalidate cache so present day main page article is always retrieved.
        [self loadArticleWithTitle: pageTitle
                          animated: YES
                   discoveryMethod: MWK_DISCOVERY_METHOD_SEARCH
                 invalidatingCache: YES
                        popToWebVC: NO];
    }
}

-(void)loadTodaysArticleIfNoCoreDataForCurrentArticle
{
    // This is needed otherwise things like TOC won't work after article core data is removed.
    // (Only used by History and Saved Pages after they delete data)
    /*
    NSManagedObjectContext *ctx = [ArticleDataContextSingleton sharedInstance].mainContext;
    __block NSManagedObjectID *articleID = nil;
    [ctx performBlockAndWait:^(){
        articleID =
            [ctx getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                               domain: [SessionSingleton sharedInstance].currentArticleDomain];
    }];
    if (!articleID) {
        [self loadTodaysArticle];
    }
     */
    [self loadTodaysArticle];
}

-(void)loadRandomArticle
{
    [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];

    (void)[[RandomArticleFetcher alloc] initAndFetchRandomArticleForDomain: [SessionSingleton sharedInstance].site.language
                                                               withManager: [QueuesSingleton sharedInstance].articleFetchManager
                                                        thenNotifyDelegate: self];
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[RandomArticleFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                NSString *title = (NSString *)fetchedData;
                if (title) {
                    MWKTitle *pageTitle = [[SessionSingleton sharedInstance].site titleWithString:title];
                    [self loadArticleWithTitle: pageTitle
                                     animated: YES
                              discoveryMethod: MWK_DISCOVERY_METHOD_RANDOM
                            invalidatingCache: NO
                                   popToWebVC: NO]; // Don't pop - popModal has already been called.
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

-(void)switchPreferredLanguageToId:(NSString *)languageId name:(NSString *)name
{
    NSString *mainArticleTitle = [SessionSingleton sharedInstance].domainMainArticleTitle;
    if (mainArticleTitle) {
        MWKSite *site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:languageId];
        MWKTitle *pageTitle = [site titleWithString:mainArticleTitle];
        
        // Invalidate cache so present day main page article is always retrieved.
        [self loadArticleWithTitle: pageTitle
                          animated: YES
                   discoveryMethod: MWK_DISCOVERY_METHOD_SEARCH
                 invalidatingCache: YES
                        popToWebVC: NO];
    }
}

@end
