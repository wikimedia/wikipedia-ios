//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BottomMenuViewController.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "SessionSingleton.h"
#import "WikiGlyph_Chars.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "UIViewController+Alert.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "NSString+Extras.h"
#import "ShareMenuSavePageActivity.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"
#import "WMF_Colors.h"
#import "UIViewController+ModalPresent.h"
#import "UIViewController+ModalsSearch.h"
#import "UIViewController+ModalPop.h"
#import "NSObject+ConstraintsScale.h"
#import "WMFShareCardViewController.h"
#import "AppDelegate.h"
#import "WMFShareFunnel.h"
#import "WMFShareOptionsViewController.h"
#import "UIWebView+WMFSuppressSelection.h"
#import "LanguagesViewController.h"

typedef NS_ENUM (NSInteger, BottomMenuItemTag) {
    BOTTOM_MENU_BUTTON_UNKNOWN,
    BOTTOM_MENU_BUTTON_PREVIOUS,
    BOTTOM_MENU_BUTTON_NEXT,
    BOTTOM_MENU_BUTTON_SHARE,
    BOTTOM_MENU_BUTTON_SAVE,
    BOTTOM_MENU_BUTTON_LANGUAGE
};

@interface BottomMenuViewController ()
<LanguageSelectionDelegate>
@property (weak, nonatomic) IBOutlet WikiGlyphButton* backButton;
@property (weak, nonatomic) IBOutlet WikiGlyphButton* forwardButton;
@property (weak, nonatomic) IBOutlet WikiGlyphButton* saveButton;
@property (weak, nonatomic) IBOutlet WikiGlyphButton* shareButton;
@property (weak, nonatomic) IBOutlet WikiGlyphButton* languagesButton;

@property (strong, nonatomic) NSDictionary* adjacentHistoryEntries;

@property (strong, nonatomic) NSArray* allButtons;

@property (strong, nonatomic) UIPopoverController* popover;
@property (strong, nonatomic) WMFShareFunnel* funnel;

@property (strong, nonatomic) WMFShareOptionsViewController* shareOptionsViewController;

@end

@implementation BottomMenuViewController {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UIColor* buttonColor = [UIColor blackColor];

    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];

    [self.languagesButton.label setWikiText:WIKIGLYPH_TRANSLATE
                                      color:buttonColor
                                       size:MENU_BOTTOM_GLYPH_FONT_SIZE
                             baselineOffset:1.5f];
    self.languagesButton.tag                = BOTTOM_MENU_BUTTON_LANGUAGE;
    self.languagesButton.accessibilityLabel = MWLocalizedString(@"menu-language-accessibility-label", nil);

    [self.backButton.label setWikiText:isRTL ? WIKIGLYPH_FORWARD : WIKIGLYPH_BACKWARD
                                 color:buttonColor
                                  size:MENU_BOTTOM_GLYPH_FONT_SIZE
                        baselineOffset:1.5f];
    self.backButton.accessibilityLabel = MWLocalizedString(@"menu-back-accessibility-label", nil);
    self.backButton.tag                = BOTTOM_MENU_BUTTON_PREVIOUS;

    [self.forwardButton.label setWikiText:isRTL ? WIKIGLYPH_BACKWARD : WIKIGLYPH_FORWARD
                                    color:buttonColor
                                     size:MENU_BOTTOM_GLYPH_FONT_SIZE
                           baselineOffset:1.5f
    ];
    self.forwardButton.accessibilityLabel = MWLocalizedString(@"menu-forward-accessibility-label", nil);
    self.forwardButton.tag                = BOTTOM_MENU_BUTTON_NEXT;
    // self.forwardButton.label.transform = CGAffineTransformMakeScale(-1, 1);

    [self.shareButton.label setWikiText:WIKIGLYPH_SHARE
                                  color:buttonColor
                                   size:MENU_BOTTOM_GLYPH_FONT_SIZE
                         baselineOffset:1.5f
    ];
    self.shareButton.tag                = BOTTOM_MENU_BUTTON_SHARE;
    self.shareButton.accessibilityLabel = MWLocalizedString(@"menu-share-accessibility-label", nil);

    [self.saveButton.label setWikiText:WIKIGLYPH_HEART_OUTLINE
                                 color:buttonColor
                                  size:MENU_BOTTOM_GLYPH_FONT_SIZE
                        baselineOffset:1.5f
    ];
    self.saveButton.tag                = BOTTOM_MENU_BUTTON_SAVE;
    self.saveButton.accessibilityLabel = MWLocalizedString(@"share-menu-save-page", nil);

    self.allButtons = @[self.backButton, self.forwardButton, self.shareButton, self.saveButton, self.languagesButton];

    self.view.backgroundColor = CHROME_COLOR;

    [self addTapRecognizersToAllButtons];

    UILongPressGestureRecognizer* saveLongPressRecognizer =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(saveButtonLongPressed:)];
    saveLongPressRecognizer.minimumPressDuration = 0.5f;
    [self.saveButton addGestureRecognizer:saveLongPressRecognizer];

    UILongPressGestureRecognizer* backLongPressRecognizer =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(backForwardButtonsLongPressed:)];
    backLongPressRecognizer.minimumPressDuration = 0.5f;
    [self.backButton addGestureRecognizer:backLongPressRecognizer];


    UILongPressGestureRecognizer* forwardLongPressRecognizer =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(backForwardButtonsLongPressed:)];
    forwardLongPressRecognizer.minimumPressDuration = 0.5f;
    [self.forwardButton addGestureRecognizer:forwardLongPressRecognizer];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shareButtonPushedWithNotification:)
                                                 name:WebViewControllerWillShareNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textWasHighlighted)
                                                 name:WebViewControllerTextWasHighlighted
                                               object:nil];

    [self adjustConstraintsScaleForViews:self.allButtons];
}

- (void)addTapRecognizersToAllButtons {
    for (WikiGlyphButton* view in self.allButtons) {
        [view addGestureRecognizer:
         [[UITapGestureRecognizer alloc] initWithTarget:self
                                                 action:@selector(buttonPushed:)]];
    }
}

- (void)setUserInteractionEnabledForAllButtons:(BOOL)enabled {
    for (WikiGlyphButton* button in self.allButtons) {
        button.userInteractionEnabled = enabled;
    }
}

#pragma mark Bottom bar button methods

- (void)buttonPushed:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded
        || ![recognizer.view isKindOfClass:[WikiGlyphButton class]]
        || ![(WikiGlyphButton*)recognizer.view enabled]) {
        return;
    }
    [self animateAndPerformActionForButton:(WikiGlyphButton*)recognizer.view
                  disableButtonInteraction:recognizer.view.tag == BOTTOM_MENU_BUTTON_SHARE];
}

- (void)animateAndPerformActionForButton:(WikiGlyphButton*)button
                disableButtonInteraction:(BOOL)shouldDisableInteraction {
    if (shouldDisableInteraction) {
        [self setUserInteractionEnabledForAllButtons:NO];
    }
    CGFloat animationScale = 1.25f;
    [button.label animateAndRewindXF:CATransform3DMakeScale(animationScale, animationScale, 1.0f)
                          afterDelay:0.0
                            duration:0.06f
                                then:^{
        [self performActionForButton:button];
        if (shouldDisableInteraction) {
            [self setUserInteractionEnabledForAllButtons:YES];
        }
    }];
}

- (void)performActionForButton:(WikiGlyphButton*)button {
    switch (button.tag) {
        case BOTTOM_MENU_BUTTON_PREVIOUS:
            [self backButtonPushed];
            break;
        case BOTTOM_MENU_BUTTON_NEXT:
            [self forwardButtonPushed];
            break;
        case BOTTOM_MENU_BUTTON_SHARE:
            [self shareUpArrowButtonPushed];
            break;
        case BOTTOM_MENU_BUTTON_SAVE:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SavePage" object:self userInfo:nil];
            [self updateBottomBarButtonsEnabledState];
            break;
        case BOTTOM_MENU_BUTTON_LANGUAGE:
            [self showLanguagePicker];
            break;
        default:
            break;
    }
}

- (void)showLanguagePicker {
    [self performModalSequeWithID:@"modal_segue_show_languages"
                  transitionStyle:UIModalTransitionStyleCoverVertical
                            block:^(LanguagesViewController* languagesVC){
        languagesVC.downloadLanguagesForCurrentArticle = YES;
        languagesVC.languageSelectionDelegate = self;
    }];
}

- (void)languageSelected:(NSDictionary*)langData sender:(LanguagesViewController*)sender {
    MWKSite* site   = [MWKSite siteWithLanguage:langData[@"code"]];
    MWKTitle* title = [site titleWithString:langData[@"*"]];
    [NAV loadArticleWithTitle:title
                     animated:NO
              discoveryMethod:MWKHistoryDiscoveryMethodSearch
                   popToWebVC:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveButtonLongPressed:(UILongPressGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self performModalSequeWithID:@"modal_segue_show_saved_pages"
                      transitionStyle:UIModalTransitionStyleCoverVertical
                                block:nil];
    }
}

- (void)backForwardButtonsLongPressed:(UILongPressGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self performModalSequeWithID:@"modal_segue_show_history"
                      transitionStyle:UIModalTransitionStyleCoverVertical
                                block:nil];
    }
}

- (void)textWasHighlighted {
    if (!self.funnel) {
        self.funnel = [[WMFShareFunnel alloc] initWithArticle:[SessionSingleton sharedInstance].currentArticle];
        [self.funnel logHighlight];
    }
}

- (void)shareUpArrowButtonPushed {
    WebViewController* webViewController = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];
    [self shareSnippet:webViewController.selectedText];
}

- (void)shareButtonPushedWithNotification:(NSNotification*)notification {
    NSString* snippet = notification.userInfo[WebViewControllerShareSelectedText];
    [self shareSnippet:snippet];
}

- (void)shareSnippet:(NSString*)snippet {
    WebViewController* webViewController = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];
    [webViewController.webView wmf_suppressSelection];
    MWKArticle* article = [SessionSingleton sharedInstance].currentArticle;

    AppDelegate* appDelegate             = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UIViewController* rootViewController = appDelegate.window.rootViewController;
    UIView* rootView                     = rootViewController.view;

    self.shareOptionsViewController = [[WMFShareOptionsViewController alloc] initWithMWKArticle:article
                                                                                        snippet:snippet
                                                                                 backgroundView:rootView
                                                                                       delegate:self];
}

#pragma mark - ShareTapDelegate methods
- (void)didShowSharePreviewForMWKArticle:(MWKArticle*)article withText:(NSString*)text {
    if (!self.funnel) {
        self.funnel = [[WMFShareFunnel alloc] initWithArticle:article];
    }
    [self.funnel logShareButtonTappedResultingInSelection:text];
}

- (void)tappedBackgroundToAbandonWithText:(NSString*)text {
    [self.funnel logAbandonedAfterSeeingShareAFact];
    [self releaseShareResources];
}

- (void)tappedShareCardWithText:(NSString*)text {
    [self.funnel logShareAsImageTapped];
}

- (void)tappedShareTextWithText:(NSString*)text {
    [self.funnel logShareAsTextTapped];
}

- (void)finishShareWithActivityItems:(NSArray*)activityItems text:(NSString*)text {
    UIActivityViewController* shareActivityVC =
        [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                          applicationActivities:@[] /*shareMenuSavePageActivity*/ ];
    NSMutableArray* exclusions = @[
        UIActivityTypePrint,
        UIActivityTypeAssignToContact,
        UIActivityTypeSaveToCameraRoll
    ].mutableCopy;

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        [exclusions addObject:UIActivityTypeAirDrop];
        [exclusions addObject:UIActivityTypeAddToReadingList];
    }

    shareActivityVC.excludedActivityTypes = exclusions;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:shareActivityVC animated:YES completion:nil];
    } else {
        // iPad crashes if you present share dialog modally. Whee!
        self.popover = [[UIPopoverController alloc] initWithContentViewController:shareActivityVC];
        [self.popover presentPopoverFromRect:self.shareButton.frame
                                      inView:self.view
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:YES];
    }

    [shareActivityVC setCompletionHandler:^(NSString* activityType, BOOL completed) {
        if (completed) {
            [self.funnel logShareSucceededWithShareMethod:activityType];
        } else {
            [self.funnel logShareFailedWithShareMethod:activityType];
        }
        [self releaseShareResources];
    }];
}

- (void)releaseShareResources {
    self.funnel                     = nil;
    self.shareOptionsViewController = nil;
}

- (void)backButtonPushed {
    MWKHistoryEntry* historyEntry = self.adjacentHistoryEntries[@"before"];
    if (historyEntry) {
        WebViewController* webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];

        [webVC showAlert:historyEntry.title.text type:ALERT_TYPE_BOTTOM duration:0.8];

        [webVC navigateToPage:historyEntry.title
              discoveryMethod:MWKHistoryDiscoveryMethodBackForward];
    }
}

- (void)forwardButtonPushed {
    MWKHistoryEntry* historyEntry = self.adjacentHistoryEntries[@"after"];
    if (historyEntry) {
        WebViewController* webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];

        [webVC showAlert:historyEntry.title.text type:ALERT_TYPE_BOTTOM duration:0.8];

        [webVC navigateToPage:historyEntry.title
              discoveryMethod:MWKHistoryDiscoveryMethodBackForward];
    }
}

- (NSDictionary*)getAdjacentHistoryEntries {
    SessionSingleton* session   = [SessionSingleton sharedInstance];
    MWKHistoryList* historyList = session.userDataStore.historyList;

    MWKHistoryEntry* currentHistoryEntry = [historyList entryForTitle:session.currentArticle.title];
    MWKHistoryEntry* beforeHistoryEntry  = [historyList entryBeforeEntry:currentHistoryEntry];
    MWKHistoryEntry* afterHistoryEntry   = [historyList entryAfterEntry:currentHistoryEntry];

    NSMutableDictionary* result = [@{} mutableCopy];
    if (beforeHistoryEntry) {
        result[@"before"] = beforeHistoryEntry;
    }
    if (currentHistoryEntry) {
        result[@"current"] = currentHistoryEntry;
    }
    if (afterHistoryEntry) {
        result[@"after"] = afterHistoryEntry;
    }

    return result;
}

- (void)updateBottomBarButtonsEnabledState {
    self.adjacentHistoryEntries = [self getAdjacentHistoryEntries];
    self.forwardButton.enabled  = (self.adjacentHistoryEntries[@"after"]) ? YES : NO;
    self.backButton.enabled     = (self.adjacentHistoryEntries[@"before"]) ? YES : NO;

    MWKArticle* currentArticle = [[SessionSingleton sharedInstance] currentArticle];
    self.languagesButton.enabled = !currentArticle.isMain && [currentArticle languagecount] > 0;

    NSString* saveIconString = WIKIGLYPH_HEART_OUTLINE;
    UIColor* saveIconColor   = [UIColor blackColor];
    if ([self isCurrentArticleSaved]) {
        saveIconString = WIKIGLYPH_HEART;
        saveIconColor  = UIColorFromRGBWithAlpha(0xf27072, 1.0);
    }

    [self.saveButton.label setWikiText:saveIconString
                                 color:saveIconColor
                                  size:MENU_BOTTOM_GLYPH_FONT_SIZE
                        baselineOffset:1.5f];
    self.funnel = nil;
}

- (BOOL)isCurrentArticleSaved {
    SessionSingleton* session = [SessionSingleton sharedInstance];
    return [session.userDataStore.savedPageList isSaved:session.currentArticle.title];
}

@end
