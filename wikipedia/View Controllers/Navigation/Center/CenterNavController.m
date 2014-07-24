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

@interface CenterNavController (){

}

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

-(void)loadArticleWithTitle: (MWPageTitle *)title
                     domain: (NSString *)domain
                   animated: (BOOL)animated
            discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
          invalidatingCache: (BOOL)invalidateCache
                 popToWebVC: (BOOL)popToWebVC
{
    WebViewController *webVC = [self searchNavStackForViewControllerOfClass:[WebViewController class]];
    if (webVC){
        [SessionSingleton sharedInstance].currentArticleTitle = title.prefixedText;
        [SessionSingleton sharedInstance].currentArticleDomain = domain;
        [webVC navigateToPage: title
                       domain: domain
              discoveryMethod: discoveryMethod
            invalidatingCache: invalidateCache];
        if (popToWebVC) {
            [ROOT popToViewController:webVC animated:animated];
        }
    }
}

-(ArticleDiscoveryMethod)getDiscoveryMethodForString:(NSString *)string
{
    if ([string isEqualToString:@"random"]) {
        return DISCOVERY_METHOD_RANDOM;
    }else if ([string isEqualToString:@"link"]) {
        return DISCOVERY_METHOD_LINK;
    }else {
        return DISCOVERY_METHOD_SEARCH;
    }
}

-(NSString *)getStringForDiscoveryMethod:(ArticleDiscoveryMethod)method
{
    switch (method) {
        case DISCOVERY_METHOD_BACKFORWARD:
            return @"backforward";
            break;
        case DISCOVERY_METHOD_RANDOM:
            return @"random";
            break;
        case DISCOVERY_METHOD_LINK:
            return @"link";
            break;
        case DISCOVERY_METHOD_SEARCH:
        default:
            return @"search";
            break;
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
    if (![SessionSingleton sharedInstance].zeroConfigState.zeroOnDialogShownOnce || ![self isTopViewControllerAWebviewController]) {
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

@end
