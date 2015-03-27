//
//  WebViewController_Private.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WebViewController.h"

#import "WikipediaAppUtils.h"
#import "WikipediaZeroMessageFetcher.h"
#import "SectionEditorViewController.h"
#import "CommunicationBridge.h"
#import "TOCViewController.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "TopMenuTextField.h"
#import "TopMenuTextFieldContainer.h"
#import "MWLanguageInfo.h"
#import "CenterNavController.h"
#import "Defines.h"
#import "UIViewController+SearchChildViewControllers.h"
#import "UIScrollView+NoHorizontalScrolling.h"
#import "UIViewController+HideKeyboard.h"
#import "UIWebView+HideScrollGradient.h"
#import "UIWebView+ElementLocation.h"
#import "UIView+RemoveConstraints.h"
#import "UIViewController+Alert.h"
#import "NSString+Extras.h"
#import "PaddedLabel.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "BottomMenuViewController.h"
#import "LanguagesViewController.h"
#import "ModalMenuAndContentViewController.h"
#import "UIViewController+ModalPresent.h"
#import "MWKSection+DisplayHtml.h"
#import "EditFunnel.h"
#import "ProtectedEditAttemptFunnel.h"
#import "DataHousekeeping.h"
#import "NSDate-Utilities.h"
#import "AccountCreationViewController.h"
#import "OnboardingViewController.h"
#import "TopMenuContainerView.h"
#import "WikiGlyph_Chars.h"
#import "UINavigationController+TopActionSheet.h"
#import "ReferencesVC.h"
#import "WMF_Colors.h"
#import "NSArray+Predicate.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "NSString+FormattedAttributedString.h"
#import "SavedPagesFunnel.h"
#import "ArticleFetcher.h"
#import "AssetsFileFetcher.h"

#import "LeadImageContainer.h"
#import "DataMigrationProgressViewController.h"
#import "UIFont+WMFStyle.h"
#import "WebViewController+ImageGalleryPresentation.h"

#import "UIWebView+WMFTrackingView.h"
#import "WMFWebViewFooterContainerView.h"
#import "UIViewController+WMFChildViewController.h"
#import "WMFWebViewFooterViewController.h"

#import "UIScrollView+WMFScrollsToTop.h"
#import "UIColor+WMFHexColor.h"

#import "WMFLoadingIndicatorOverlay.h"

//#import "UIView+Debugging.h"

#define TOC_TOGGLE_ANIMATION_DURATION @0.225f

static const CGFloat kScrollIndicatorLeftMargin        = 2.0f;
static const CGFloat kScrollIndicatorWidth             = 2.5f;
static const CGFloat kScrollIndicatorHeight            = 25.0f;
static const CGFloat kScrollIndicatorCornerRadius      = 2.0f;
static const CGFloat kScrollIndicatorBorderWidth       = 1.0f;
static const CGFloat kScrollIndicatorAlpha             = 0.3f;
static const NSInteger kScrollIndicatorBorderColor     = 0x000000;
static const NSInteger kScrollIndicatorBackgroundColor = 0x000000;

static const CGFloat kBottomScrollSpacerHeight = 2000.0f;

// This controls how fast the swipe has to be (side-to-side).
#define TOC_SWIPE_TRIGGER_MIN_X_VELOCITY 600.0f
// This controls what angle from the horizontal axis will trigger the swipe.
#define TOC_SWIPE_TRIGGER_MAX_ANGLE 45.0f

// TODO: rename the WebViewControllerVariableNames once we rename this class

// Some dialects have complex characters, so we use 2 instead of 10
static const int kMinimumTextSelectionLength = 2;

@interface WebViewController ()
{
    CGFloat scrollViewDragBeganVerticalOffset_;
    SessionSingleton* session;
}

@property (strong, nonatomic) CommunicationBridge* bridge;

@property (nonatomic) CGPoint lastScrollOffset;

@property (nonatomic) BOOL unsafeToScroll;

@property (nonatomic) float relativeScrollOffsetBeforeRotate;
@property (nonatomic) NSUInteger sectionToEditId;

@property (strong, nonatomic) NSDictionary* adjacentHistoryIDs;
@property (strong, nonatomic) NSString* externalUrl;

@property (weak, nonatomic) IBOutlet UIView* bottomBarView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* tocViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* tocViewLeadingConstraint;

@property (strong, nonatomic) UIView* scrollIndicatorView;
@property (strong, nonatomic) NSLayoutConstraint* scrollIndicatorViewTopConstraint;
@property (strong, nonatomic) NSLayoutConstraint* scrollIndicatorViewHeightConstraint;

@property (strong, nonatomic) TOCViewController* tocVC;

@property (strong, nonatomic) UIPanGestureRecognizer* panSwipeRecognizer;

@property (strong, nonatomic) IBOutlet PaddedLabel* zeroStatusLabel;

@property (nonatomic) BOOL unsafeToToggleTOC;

@property (strong, nonatomic) ReferencesVC* referencesVC;
@property (weak, nonatomic) IBOutlet UIView* referencesContainerView;

@property (strong, nonatomic) NSLayoutConstraint* bottomBarViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* referencesContainerViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* referencesContainerViewHeightConstraint;

@property (copy) NSString* jumpToFragment;

@property (nonatomic) BOOL editable;
@property (copy) MWKProtectionStatus* protectionStatus;

// These are presently only used by updateHistoryDateVisitedForArticleBeingNavigatedFrom method.
@property (strong, nonatomic) MWKTitle* currentTitle;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* bottomNavHeightConstraint;

@property (strong, nonatomic) WMFLoadingIndicatorOverlay* loadingIndicatorOverlay;

@property (strong, nonatomic) LeadImageContainer* leadImageContainer;

@property (strong, nonatomic) WMFWebViewFooterContainerView* footerContainer;
@property (strong, nonatomic) WMFWebViewFooterViewController* footerViewController;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* webViewBottomConstraint;

@property (nonatomic) BOOL didLastNavigateByBackOrForward;

@property (nonatomic) BOOL isCurrentArticleMain;

@property (nonatomic) BOOL keyboardIsVisible;


- (void)cancelArticleLoading;

- (void)cancelSearchLoading;

@end
