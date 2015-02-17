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
#import "SuggestionsFooterViewController.h"
#import "OptionsFooterViewController.h"
#import "LegalFooterViewController.h"
#import "WebViewBottomTrackingContainerView.h"

//#import "UIView+Debugging.h"

#define TOC_TOGGLE_ANIMATION_DURATION @0.225f

#define SCROLL_INDICATOR_LEFT_MARGIN 2.0
#define SCROLL_INDICATOR_WIDTH 4.0
#define SCROLL_INDICATOR_HEIGHT 25.0
#define SCROLL_INDICATOR_CORNER_RADIUS 2.0f
#define SCROLL_INDICATOR_BORDER_WIDTH 1.0f
#define SCROLL_INDICATOR_BORDER_COLOR [UIColor lightGrayColor]
#define SCROLL_INDICATOR_BACKGROUND_COLOR [UIColor whiteColor]

static const CGFloat kBottomScrollSpacerHeight = 2000.0f;

// This controls how fast the swipe has to be (side-to-side).
#define TOC_SWIPE_TRIGGER_MIN_X_VELOCITY 600.0f
// This controls what angle from the horizontal axis will trigger the swipe.
#define TOC_SWIPE_TRIGGER_MAX_ANGLE 45.0f

// TODO: rename the WebViewControllerVariableNames once we rename this class

static const int kMinimumTextSelectionLength = 10;

@interface WebViewController ()
{
    CGFloat scrollViewDragBeganVerticalOffset_;
    SessionSingleton *session;
}

@property (strong, nonatomic) CommunicationBridge *bridge;

@property (nonatomic) CGPoint lastScrollOffset;

@property (nonatomic) BOOL unsafeToScroll;

@property (nonatomic) float relativeScrollOffsetBeforeRotate;
@property (nonatomic) NSUInteger sectionToEditId;

@property (strong, nonatomic) NSDictionary *adjacentHistoryIDs;
@property (strong, nonatomic) NSString *externalUrl;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tocViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tocViewLeadingConstraint;

@property (strong, nonatomic) UIView *scrollIndicatorView;
@property (strong, nonatomic) NSLayoutConstraint *scrollIndicatorViewTopConstraint;
@property (strong, nonatomic) NSLayoutConstraint *scrollIndicatorViewHeightConstraint;

@property (strong, nonatomic) TOCViewController *tocVC;

@property (strong, nonatomic) UIPanGestureRecognizer* panSwipeRecognizer;

@property (strong, nonatomic) IBOutlet PaddedLabel *zeroStatusLabel;

@property (nonatomic) BOOL unsafeToToggleTOC;

@property (strong, nonatomic) ReferencesVC *referencesVC;
@property (weak, nonatomic) IBOutlet UIView *referencesContainerView;

@property (strong, nonatomic) NSLayoutConstraint *bottomBarViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *referencesContainerViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *referencesContainerViewHeightConstraint;

@property (copy) NSString *jumpToFragment;

@property (nonatomic) BOOL editable;
@property (copy) MWKProtectionStatus *protectionStatus;

// These are presently only used by updateHistoryDateVisitedForArticleBeingNavigatedFrom method.
@property (strong, nonatomic) MWKTitle *currentTitle;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomNavHeightConstraint;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIView *activityIndicatorBackgroundView;

@property (strong, nonatomic) LeadImageContainer *leadImageContainer;

@property (strong, nonatomic) WebViewBottomTrackingContainerView *footerContainer;
@property (strong, nonatomic) OptionsFooterViewController *footerOptionsController;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewBottomConstraint;

@property (nonatomic) BOOL didLastNavigateByBackOrForward;

- (void)cancelArticleLoading;

- (void)cancelSearchLoading;

@end
