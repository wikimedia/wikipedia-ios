//
//  WebViewController_Private.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFWebViewController.h"

#import "WikipediaAppUtils.h"
#import "WikipediaZeroMessageFetcher.h"
#import "SectionEditorViewController.h"
#import "CommunicationBridge.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "MWLanguageInfo.h"
#import "Defines.h"
#import "UIScrollView+NoHorizontalScrolling.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "UIWebView+ElementLocation.h"
#import "UIView+RemoveConstraints.h"
#import "UIViewController+Alert.h"
#import "NSString+Extras.h"
#import "PaddedLabel.h"
#import "LanguagesViewController.h"
#import "MWKSection+DisplayHtml.h"
#import "EditFunnel.h"
#import "ProtectedEditAttemptFunnel.h"
#import "DataHousekeeping.h"
#import "NSDate-Utilities.h"
#import "AccountCreationViewController.h"
#import "WikiGlyph_Chars.h"
#import "UINavigationController+TopActionSheet.h"
#import "ReferencesVC.h"
#import "WMF_Colors.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "NSString+FormattedAttributedString.h"
#import "SavedPagesFunnel.h"
#import "AssetsFileFetcher.h"

#import "DataMigrationProgressViewController.h"
#import "UIFont+WMFStyle.h"
#import "WebViewController+ImageGalleryPresentation.h"

#import "UIScrollView+WMFScrollsToTop.h"
#import "UIColor+WMFHexColor.h"

#import "WMFArticleImageProtocol.h"
#import "WMFURLCache.h"

#import "WMFProgressLineView.h"

//#import "UIView+Debugging.h"

#define TOC_TOGGLE_ANIMATION_DURATION @0.225f

static CGFloat const kScrollIndicatorLeftMargin        = 2.0f;
static CGFloat const kScrollIndicatorWidth             = 2.5f;
static CGFloat const kScrollIndicatorHeight            = 25.0f;
static CGFloat const kScrollIndicatorCornerRadius      = 2.0f;
static CGFloat const kScrollIndicatorBorderWidth       = 1.0f;
static CGFloat const kScrollIndicatorAlpha             = 0.3f;
static NSInteger const kScrollIndicatorBorderColor     = 0x000000;
static NSInteger const kScrollIndicatorBackgroundColor = 0x000000;

// This controls how fast the swipe has to be (side-to-side).
#define TOC_SWIPE_TRIGGER_MIN_X_VELOCITY 600.0f
// This controls what angle from the horizontal axis will trigger the swipe.
#define TOC_SWIPE_TRIGGER_MAX_ANGLE 45.0f

// TODO: rename the WebViewControllerVariableNames once we rename this class

// Some dialects have complex characters, so we use 2 instead of 10
static int const kMinimumTextSelectionLength = 2;

@interface WMFWebViewController ()

@property (nonatomic, strong, readwrite) IBOutlet UIWebView* webView;

@property (nonatomic, strong) SessionSingleton* session;

@property (strong, nonatomic) CommunicationBridge* bridge;

@property (nonatomic) CGPoint lastScrollOffset;

@property (nonatomic) CGFloat scrollViewDragBeganVerticalOffset;

@property (strong, nonatomic) NSDictionary* adjacentHistoryIDs;
@property (strong, nonatomic) NSString* externalUrl;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* tocViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* tocViewLeadingConstraint;

@property (strong, nonatomic) UIPanGestureRecognizer* panSwipeRecognizer;

@property (strong, nonatomic) IBOutlet PaddedLabel* zeroStatusLabel;

@property (strong, nonatomic) ReferencesVC* referencesVC;
@property (weak, nonatomic) IBOutlet UIView* referencesContainerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* referencesContainerViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* referencesContainerViewHeightConstraint;

@property (copy) NSString* jumpToFragment;

@property (nonatomic) BOOL editable;
@property (copy) MWKProtectionStatus* protectionStatus;

// These are presently only used by updateHistoryDateVisitedForArticleBeingNavigatedFrom method.
@property (strong, nonatomic) MWKTitle* currentTitle;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* webViewBottomConstraint;

@property (nonatomic) BOOL isCurrentArticleMain;

@property (nonatomic) BOOL keyboardIsVisible;

@property (strong, nonatomic) WMFProgressLineView* progressView;

@property (assign, nonatomic) BOOL isFetchingArticle;

/**
 * Designated initializer.
 * @param session The current session, defaults to `+[SessionSingleton sharedInstance]`.
 * @return A new `WebViewController` with the given session.
 */
- (instancetype)initWithSession:(SessionSingleton*)session;

- (void)displayArticle:(MWKTitle*)title;

- (void)cancelArticleLoading;

- (void)cancelSearchLoading;

@end
