//  Created by Monte Hurd on 2/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PreviewAndSaveViewController.h"
#import "WikipediaAppUtils.h"
#import "PreviewHtmlFetcher.h"
#import "UIViewController+Alert.h"
#import "QueuesSingleton.h"
#import "CenterNavController.h"
#import "WikiTextSectionUploader.h"
#import "CaptchaViewController.h"
#import "UIViewController+HideKeyboard.h"
#import "EditTokenFetcher.h"
#import "SessionSingleton.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "PreviewWebView.h"
#import "UINavigationController+TopActionSheet.h"
#import "Defines.h"
#import "WMF_Colors.h"
#import "CommunicationBridge.h"
#import "PaddedLabel.h"
#import "NSString+Extras.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "MenuButton.h"
#import "EditSummaryViewController.h"
#import "UIViewController+ModalPresent.h"
#import "PreviewLicenseView.h"
#import "LoginViewController.h"
#import "UIScrollView+ScrollSubviewToLocation.h"
#import "AbuseFilterAlert.h"
#import "MWLanguageInfo.h"
#import "NSObject+ConstraintsScale.h"

typedef enum {
    CANNED_SUMMARY_TYPOS = 0,
    CANNED_SUMMARY_GRAMMAR = 1,
    CANNED_SUMMARY_LINKS = 2,
    CANNED_SUMMARY_OTHER = 3
} CannedSummaryChoices;

@interface PreviewAndSaveViewController ()

@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) CaptchaViewController *captchaViewController;
@property (weak, nonatomic) IBOutlet UIView *captchaContainer;
@property (weak, nonatomic) IBOutlet UIScrollView *captchaScrollView;
@property (weak, nonatomic) IBOutlet UIView *captchaScrollContainer;
@property (weak, nonatomic) IBOutlet UIView *editSummaryContainer;
@property (weak, nonatomic) IBOutlet UIWebView *previewWebView;
@property (strong, nonatomic) CommunicationBridge *bridge;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewWebViewHeightConstraint;
@property (strong, nonatomic) UILabel *aboutLabel;
@property (strong, nonatomic) MenuButton *cannedSummary01;
@property (strong, nonatomic) MenuButton *cannedSummary02;
@property (strong, nonatomic) MenuButton *cannedSummary03;
@property (strong, nonatomic) MenuButton *cannedSummary04;
@property (nonatomic) CGFloat borderWidth;
@property (weak, nonatomic) IBOutlet PreviewLicenseView *previewLicenseView;
@property (strong, nonatomic) UIGestureRecognizer *previewLicenseTapGestureRecognizer;
@property (strong, nonatomic) IBOutlet PaddedLabel *previewLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
//@property (nonatomic) BOOL saveAutomaticallyIfSignedIn;

@end

@implementation PreviewAndSaveViewController

-(NSString *)getSummary
{
    NSMutableArray *summaryArray = @[].mutableCopy;
    
    if (self.cannedSummary01.enabled) [summaryArray addObject:self.cannedSummary01.text];
    if (self.cannedSummary02.enabled) [summaryArray addObject:self.cannedSummary02.text];
    if (self.cannedSummary03.enabled) [summaryArray addObject:self.cannedSummary03.text];

    if (self.cannedSummary04.enabled) {
        if (self.summaryText && (self.summaryText.length > 0)) {
            [summaryArray addObject:self.summaryText];
        }
    }

    return [summaryArray componentsJoinedByString:@"; "];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)setupBridge
{
    self.bridge = [[CommunicationBridge alloc] initWithWebView: self.previewWebView];

    //[self.bridge addListener:@"DOMContentLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
    //}];

    __weak PreviewAndSaveViewController *weakSelf = self;

    [self.bridge addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        [weakSelf.previewWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", payload[@"href"]]];
    }];
}

// Handle nav bar taps.
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_BUTTON_ARROW_LEFT:
            [ROOT popViewControllerAnimated:YES];
            
            if(ROOT.topMenuViewController.navBarMode == NAVBAR_MODE_EDIT_WIKITEXT_WARNING){
                [self.funnel logAbuseFilterWarningBack:self.abuseFilterCode];
            }
            
            break;
        case NAVBAR_BUTTON_SAVE: /* for captcha submit button */
        case NAVBAR_BUTTON_CHECK:
            {
                switch (ROOT.topMenuViewController.navBarMode) {
                    case NAVBAR_MODE_EDIT_WIKITEXT_WARNING:
                        [self save];
                        [self.funnel logAbuseFilterWarningIgnore:self.abuseFilterCode];
                        break;
                    case NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA:
                        [self save];
                        break;
                    default:
                        [self save];
                        break;
                }
            }
            break;
        default:
            break;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PreviewWebViewBeganScrolling" object:self userInfo:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.summaryText = @"";
    
    self.previewLabel.font = [UIFont boldSystemFontOfSize:15.0 * MENUS_SCALE_MULTIPLIER];

    self.previewLabel.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-preview", nil);
    
    [self.previewLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewLabelTapped:)]];
    
    //self.saveAutomaticallyIfSignedIn = NO;

    [self setupBridge];
    
    self.previewWebView.scrollView.delegate = self;
    
    self.captchaId = @"";

    self.navigationItem.hidesBackButton = YES;

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(htmlAlertWasHidden)
                                                 name: @"HtmlAlertWasHidden"
                                               object: nil];

    [self.funnel logPreview];

    self.borderWidth = 1.0f / [UIScreen mainScreen].scale;

    [self setupEditSummaryContainerSubviews];
    
    [self constrainEditSummaryContainerSubviews];

    // Disable the preview web view's scrolling since we're going to size it
    // such that its internal scroll view isn't ever going to be visble anyway.
    self.previewWebView.scrollView.scrollEnabled = NO;

    // Observer the web view's contentSize property to enable the web view to expand to the
    // height of the html content it is displaying so the web view's scroll view doesn't show
    // any scroll bars. (Expand the web view to the full height of its content so it scrolls
    // with this view controller's scroll view rather than its own.) Note that to make this
    // work, the PreviewWebView object also uses a method called
    // "forceScrollViewContentSizeToReflectActualHTMLHeight".
    [self.previewWebView.scrollView addObserver: self
                                     forKeyPath: @"contentSize"
                                        options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                                        context: nil];
    [self preview];
}

-(void)previewLabelTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.scrollView scrollSubViewToTop:self.previewLabel animated:YES];
    }
}

-(void)dealloc
{
    [self.previewWebView.scrollView removeObserver:self forKeyPath:@"contentSize"];
}

-(void)observeValueForKeyPath: (NSString *)keyPath
                     ofObject: (id)object
                       change: (NSDictionary *)change
                      context: (void *)context
{
    if (
        (object == self.previewWebView.scrollView)
        &&
        [keyPath isEqual:@"contentSize"]
        ) {
        // Size the web view to the height of the html content it is displaying (gets rid of the web view's scroll bars).
        // Note: the PreviewWebView class has to call "forceScrollViewContentSizeToReflectActualHTMLHeight" in its
        // overridden "layoutSubviews" method for the contentSize to be reported accurately such that it reflects the
        // actual height of the web view content here. Without the web view class calling this method in its
        // layoutSubviews, the contentSize.height wouldn't change if we, say, rotated the device.
        self.previewWebViewHeightConstraint.constant = self.previewWebView.scrollView.contentSize.height;
    }
}

-(void)constrainEditSummaryContainerSubviews
{
    NSDictionary *views = @{
                            @"aboutLabel": self.aboutLabel,
                            @"cannedSummary01": self.cannedSummary01,
                            @"cannedSummary02": self.cannedSummary02,
                            @"cannedSummary03": self.cannedSummary03,
                            @"cannedSummary04": self.cannedSummary04
                            };

    // Tighten up the spacing for 3.5 inch screens.
    CGFloat spaceAboveCC = ([UIScreen mainScreen].bounds.size.height != 480) ? 43 : 4;
    
    NSDictionary *metrics = @{
                            @"buttonHeight": @(48),
                            @"spaceAboveCC": @(spaceAboveCC)
                            };
    
    NSArray *constraints = @[
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[aboutLabel]|" options:0 metrics:metrics views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cannedSummary01]" options:0 metrics:metrics views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cannedSummary02]" options:0 metrics:metrics views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cannedSummary03]" options:0 metrics:metrics views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cannedSummary04]" options:0 metrics:metrics views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(40)-[aboutLabel]-(5)-[cannedSummary01(buttonHeight)][cannedSummary02(buttonHeight)][cannedSummary03(buttonHeight)][cannedSummary04(buttonHeight)]-(spaceAboveCC)-|" options:0 metrics:metrics views:views]
    ];
    [self.editSummaryContainer addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];

    [self adjustConstraintsScaleForViews:@[self.cannedSummary01, self.cannedSummary02, self.cannedSummary03, self.cannedSummary04, self.editSummaryContainer, self.aboutLabel]];
}

-(void)setupEditSummaryContainerSubviews
{
    // Setup the canned edit summary buttons.
    UIColor *color = [UIColor colorWithRed:0.03 green:0.48 blue:0.92 alpha:1.0];
    UIEdgeInsets padding = UIEdgeInsetsMake(6, 10, 6, 10);
    UIEdgeInsets margin = UIEdgeInsetsMake(8, 0, 8, 0);
    CGFloat fontSize = 14.0;
    
    MenuButton * (^setupButton)(NSString *, NSInteger) = ^MenuButton *(NSString *text, NSInteger tag) {
        MenuButton *button = [[MenuButton alloc] initWithText: text
                                                     fontSize: fontSize
                                                         bold: NO
                                                        color: color
                                                      padding: padding
                                                       margin: margin];
        button.enabled = NO;
        button.tag = tag;
        [button addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapped:)]];
        [self.editSummaryContainer addSubview:button];
        return button;
    };
    
    self.cannedSummary01 = setupButton(MWLocalizedString(@"edit-summary-choice-fixed-typos", nil), CANNED_SUMMARY_TYPOS);
    self.cannedSummary02 = setupButton(MWLocalizedString(@"edit-summary-choice-fixed-grammar", nil), CANNED_SUMMARY_GRAMMAR);
    self.cannedSummary03 = setupButton(MWLocalizedString(@"edit-summary-choice-linked-words", nil), CANNED_SUMMARY_LINKS);
    self.cannedSummary04 = setupButton(MWLocalizedString(@"edit-summary-choice-other", nil), CANNED_SUMMARY_OTHER);

    // Setup the canned edit summaries label.
    self.aboutLabel = [[UILabel alloc] init];
    self.aboutLabel.numberOfLines = 0;
    self.aboutLabel.font = [UIFont boldSystemFontOfSize:24.0 * MENUS_SCALE_MULTIPLIER];
    self.aboutLabel.textColor = [UIColor darkGrayColor];
    self.aboutLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.aboutLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.aboutLabel.text = MWLocalizedString(@"edit-summary-title", nil);
    self.aboutLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    
    [self.editSummaryContainer addSubview:self.aboutLabel];
}

-(void)buttonTapped:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        MenuButton *tappedButton = (MenuButton *)recognizer.view;
        
        NSString *summaryKey;
        switch (tappedButton.tag) {
            case CANNED_SUMMARY_TYPOS:
                summaryKey = @"typo";
                break;
            case CANNED_SUMMARY_GRAMMAR:
                summaryKey = @"grammar";
                break;
            case CANNED_SUMMARY_LINKS:
                summaryKey = @"links";
                break;
            case CANNED_SUMMARY_OTHER:
                summaryKey = @"other";
                break;
            default:
                NSLog(@"unrecognized button");
        }
        [self.funnel logEditSummaryTap:summaryKey];
        
        switch (tappedButton.tag) {
            case CANNED_SUMMARY_OTHER:
                [self showSummaryOverlay];
                break;
                
            default:
                tappedButton.enabled = !tappedButton.enabled;
                
                break;
        }
    }
}

- (void)showSummaryOverlay
{
    [self performModalSequeWithID: @"modal_segue_show_edit_summary"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: ^(EditSummaryViewController *summaryVC){
                                // Set the overlay's text field to self.summaryText so it can display
                                // any existing value (in case user taps "Other" again)
                                summaryVC.summaryText = self.summaryText;
                                summaryVC.previewVC = self;
                            }];
}

-(void)htmlAlertWasHidden
{
    [ROOT popViewControllerAnimated:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.captchaScrollView.alpha = 0.0f;

    ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW;

    MenuButton *button = (MenuButton *)[ROOT.topMenuViewController getNavBarItem:NAVBAR_BUTTON_SAVE];
    button.enabled = YES;

    //[self saveAutomaticallyIfNecessary];

    // Highlight the "Other" button if the user entered some "other" text.
    self.cannedSummary04.enabled = (self.summaryText.length > 0) ? YES : NO;

    BOOL userIsloggedIn = [SessionSingleton sharedInstance].keychainCredentials.userName ? YES : NO;
    if (userIsloggedIn) {
        self.previewLicenseView.licenseLoginLabel.userInteractionEnabled = NO;
        self.previewLicenseView.licenseLoginLabel.attributedText = nil;
    }else{
        self.previewLicenseView.licenseLoginLabel.userInteractionEnabled = YES;
    }

    self.previewLicenseTapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(licenseLabelTapped:)];
    [self.previewLicenseView.licenseLoginLabel addGestureRecognizer:self.previewLicenseTapGestureRecognizer];

    [super viewWillAppear:animated];
}

-(void)licenseLabelTapped:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {        
        // Call if user taps the blue "Log In" text in the CC text.
        //self.saveAutomaticallyIfSignedIn = YES;
        [self performModalSequeWithID: @"modal_segue_show_login"
                      transitionStyle: UIModalTransitionStyleCoverVertical
                                block: ^(LoginViewController *loginVC){
                                    loginVC.funnel = [[LoginFunnel alloc] init];
                                    [loginVC.funnel logStartFromEdit:self.funnel.editSessionToken];
                                }];
    }
}

-(void)highlightCaptchaSubmitButton:(BOOL)highlight
{
    MenuButton *button = (MenuButton *)[ROOT.topMenuViewController getNavBarItem:NAVBAR_BUTTON_SAVE];
    button.enabled = highlight;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [self.navigationController topActionSheetHide];

    [self fadeAlert];

    // Change the nav bar layout.
    //ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT;

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"TabularScrollViewItemTapped"
                                                  object: nil];

    [self.previewLicenseView.licenseLoginLabel removeGestureRecognizer:self.previewLicenseTapGestureRecognizer];

    [super viewWillDisappear:animated];
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[PreviewHtmlFetcher class]]) {
        
        MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:self.section.site.language];
        NSString *uidir = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");
        
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                [self fadeAlert];

                [self.bridge loadHTML:fetchedData withAssetsFile:@"preview.html"];

                [self.bridge sendMessage: @"setLanguage"
                             withPayload: @{
                                            @"lang": languageInfo.code,
                                            @"dir": languageInfo.dir,
                                            @"uidir": uidir
                                            }];
            }
                break;
            case FETCH_FINAL_STATUS_FAILED:{
                NSString *errorMsg = error.localizedDescription;
                [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:{
                NSString *errorMsg = error.localizedDescription;
                [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
            }
                break;
        }
        
    }else if ([sender isKindOfClass:[EditTokenFetcher class]]) {
        
        EditTokenFetcher *tokenFetcher = (EditTokenFetcher *)sender;
        
        void (^upload)() = ^void() {
            NSMutableDictionary *editTokens = [SessionSingleton sharedInstance].keychainCredentials.editTokens;
            NSString *editToken = editTokens[tokenFetcher.title.site.language];
            (void)[[WikiTextSectionUploader alloc] initAndUploadWikiText: tokenFetcher.wikiText
                                                            forPageTitle: tokenFetcher.title
                                                                 section: tokenFetcher.section
                                                                 summary: tokenFetcher.summary
                                                               captchaId: tokenFetcher.captchaId
                                                             captchaWord: tokenFetcher.captchaWord
                                                                   token: editToken
                                                             withManager: [QueuesSingleton sharedInstance].sectionWikiTextUploadManager
                                                      thenNotifyDelegate: self];
        };
        
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                NSMutableDictionary *editTokens =
                [SessionSingleton sharedInstance].keychainCredentials.editTokens;
                //NSLog(@"article.domain = %@", article.domain);
                NSString *domain = [sender domain];
                if (domain && tokenFetcher.token) {
                    editTokens[domain] = tokenFetcher.token;
                    [SessionSingleton sharedInstance].keychainCredentials.editTokens = editTokens;
                }
                upload();
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;
            case FETCH_FINAL_STATUS_FAILED:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                
                // Still try the uploadWikiTextOp even if EditTokenFetcher fails to get a token.
                // EditTokenFetcher return an anonymous "+\" edit token if it doesn't find an edit token.
                upload();
                
                break;
        }
        
    } else if ([sender isKindOfClass:[WikiTextSectionUploader class]]) {
        
        WikiTextSectionUploader *uploader = (WikiTextSectionUploader *)sender;
        
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                
                [self.funnel logSavedRevision:[fetchedData[@"newrevid"] intValue]];
                
                // Mark article for refreshing and reload it.
                //if (uploader.articleID) {
                    
                    WebViewController *webVC = [self.navigationController searchNavStackForViewControllerOfClass:[WebViewController class]];
                    [webVC reloadCurrentArticleInvalidatingCache:YES];
                    [ROOT popToViewController:webVC animated:YES];
                //}
            }
                break;
                
            case FETCH_FINAL_STATUS_CANCELLED:{
                
                NSString *errorMsg = error.localizedDescription;
                [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
            }
                break;
                
            case FETCH_FINAL_STATUS_FAILED:{
                
                NSString *errorMsg = error.localizedDescription;
                
                [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
                
                switch (error.code) {
                    case WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA:
                    {
                        
                        if(ROOT.topMenuViewController.navBarMode == NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA){
                            [self.funnel logCaptchaFailure];
                        }
                        
                        // If the server said a captcha was required, present the captcha image.
                        NSString *captchaUrl = error.userInfo[@"captchaUrl"];
                        NSString *captchaId = error.userInfo[@"captchaId"];
                        MWKArticle *article = self.section.article;
                        [UIView animateWithDuration:0.2f animations:^{
                            
                            [self revealCaptcha];
                            
                            [self.captchaViewController.captchaTextBox performSelector: @selector(becomeFirstResponder)
                                                                            withObject: nil
                                                                            afterDelay: 0.4f];
                            
                            [self.captchaViewController showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
                            
                            self.captchaViewController.captchaImageView.image = nil;
                            
                            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                                // Background thread.
                                
                                NSURL *captchaImageUrl = [NSURL URLWithString:
                                                          [NSString stringWithFormat:@"https://%@.m.%@%@", article.site.language, article.site.domain, captchaUrl]
                                                          ];
                                
                                UIImage *captchaImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:captchaImageUrl]];
                                
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    // Main thread.
                                    self.captchaViewController.captchaTextBox.text = @"";
                                    self.captchaViewController.captchaImageView.image = captchaImage;
                                    self.captchaId = captchaId;
                                    
                                    [self.view layoutIfNeeded];
                                });
                            });
                            
                        } completion:^(BOOL done){
                        }];
                    }
                        break;
                        
                    case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED:
                    case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING:
                    case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER:
                    {
                        //NSString *warningHtml = error.userInfo[@"warning"];
                        
                        [self hideKeyboard];
                        
                        NSString *bannerImage = nil;
                        UIColor *bannerColor = nil;
                        
                        if ((error.code == WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED)) {
                            ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW;
                            bannerImage = @"abuse-filter-disallowed.png";
                            bannerColor = WMF_COLOR_RED;
                            
                            self.abuseFilterCode = error.userInfo[@"code"];
                            [self.funnel logAbuseFilterError:self.abuseFilterCode];
                            
                        }else{
                            ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_WARNING;
                            
                            //[self highlightProgressiveButtons:YES];
                            
                            bannerImage = @"abuse-filter-flag-white.png";
                            bannerColor = WMF_COLOR_ORANGE;
                            
                            self.abuseFilterCode = error.userInfo[@"code"];
                            [self.funnel logAbuseFilterWarning:self.abuseFilterCode];
                            
                        }
                        
                        // Hides the license panel. Needed if logged in and a disallow is triggered.
                        [self.navigationController topActionSheetHide];
                        
                        [self fadeAlert];
                        AbuseFilterAlertType alertType =
                        (error.code == WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED) ? ABUSE_FILTER_DISALLOW : ABUSE_FILTER_WARNING;
                        [self showAbuseFilterAlertOfType:alertType];
                        
                    }
                        break;
                        
                    case WIKITEXT_UPLOAD_ERROR_SERVER:
                    case WIKITEXT_UPLOAD_ERROR_UNKNOWN:
                        
                        [self.funnel logError:error.localizedDescription]; // @fixme is this right msg?
                        break;
                        
                    default:
                        break;
                }
            }
                break;
        }
    }
}

- (void)preview
{
    [self showAlert:MWLocalizedString(@"wikitext-preview-changes", nil) type:ALERT_TYPE_TOP duration:-1];
 
    [[QueuesSingleton sharedInstance].sectionPreviewHtmlFetchManager.operationQueue cancelAllOperations];

    (void)[[PreviewHtmlFetcher alloc] initAndFetchHtmlForWikiText: self.wikiText
                                                            title: self.section.article.title
                                                      withManager: [QueuesSingleton sharedInstance].sectionPreviewHtmlFetchManager
                                               thenNotifyDelegate: self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
-(void)saveAutomaticallyIfNecessary
{
    // Save automatically if user had tapped "sign in and save" previously and if
    // the view is appearing and the user is now logged in.
    if(self.saveAutomaticallyIfSignedIn){
        self.saveAutomaticallyIfSignedIn = NO;
        if([SessionSingleton sharedInstance].keychainCredentials.userName){
            [self save];
        }
    }
}
*/

- (void)save
{

//TODO: maybe? if we have credentials, yet the edit token retrieved for an edit
// is an anonymous token (i think this happens if you try to get an edit token
// and your login session has expired), need to pop up alert asking user if they
// want to log in before continuing with their edit

    [self showAlert:MWLocalizedString(@"wikitext-upload-save", nil) type:ALERT_TYPE_TOP duration:-1];

    [self.funnel logSaveAttempt];
    if (self.savedPagesFunnel) {
        [self.savedPagesFunnel logEditAttempt];
    }

    [[QueuesSingleton sharedInstance].sectionWikiTextUploadManager.operationQueue cancelAllOperations];

    // If fromTitle was set, the section was transcluded, so use the title of the page
    // it was transcluded from.

    // First try to get an edit token for the page's domain before trying to upload the changes.
    // Only the domain is used to actually fetch the token, the other values are
    // parked in EditTokenFetcher so the actual uploader can have quick read-only
    // access to the exact params which kicked off the token request.
    (void)[[EditTokenFetcher alloc] initAndFetchEditTokenForWikiText: self.wikiText
                                                           pageTitle: self.section.fromtitle
                                                             section: self.section.index
                                                             summary: [self getSummary]
                                                           captchaId: self.captchaId
                                                         captchaWord: self.captchaViewController.captchaTextBox.text
                                                         withManager: [QueuesSingleton sharedInstance].sectionWikiTextUploadManager
                                                  thenNotifyDelegate: self];
}

-(void)showAbuseFilterAlertOfType:(AbuseFilterAlertType)alertType
{
    AbuseFilterAlert *abuseFilterAlert = [[AbuseFilterAlert alloc] initWithType:alertType];
    
    [self.view addSubview:abuseFilterAlert];
    
    NSDictionary *views = @{@"abuseFilterAlert": abuseFilterAlert};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|[abuseFilterAlert]|"
                                                                      options: 0
                                                                      metrics: nil
                                                                        views: views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:|[abuseFilterAlert]|"
                                                                      options: 0
                                                                      metrics: nil
                                                                        views: views]];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"Preview_Captcha_Embed"]) {
		self.captchaViewController = (CaptchaViewController *) [segue destinationViewController];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == self.captchaViewController.captchaTextBox) {
        [self save];
    }
    return YES;
}

- (void)reloadCaptchaPushed:(id)sender
{ 
    // Send a bad captcha response to get a new captcha image.
    self.captchaViewController.captchaTextBox.text = @"";
    [self save];
}

-(void)revealCaptcha
{
    [self.funnel logCaptchaShown];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.35];
    [UIView setAnimationTransition: UIViewAnimationTransitionNone
                           forView: self.view
                             cache: NO];
    
    [self.view bringSubviewToFront:self.captchaScrollView];
    
    self.captchaScrollView.alpha = 1.0f;
    self.captchaScrollView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.98];

    self.captchaScrollContainer.backgroundColor = [UIColor clearColor];
    self.captchaContainer.backgroundColor = [UIColor clearColor];
    
    [UIView commitAnimations];
    
    ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA;
    
    [self highlightCaptchaSubmitButton:NO];

    [self.captchaViewController.captchaTextBox addTarget: self
                                                  action: @selector(captchaTextFieldDidChange:)
                                        forControlEvents: UIControlEventEditingChanged];
}

-(void)captchaTextFieldDidChange:(UITextField *)textField
{
    [self highlightCaptchaSubmitButton:(textField.text.length == 0) ? NO : YES];
}

//    BOOL userIsloggedIn = [SessionSingleton sharedInstance].keychainCredentials.userName ? YES : NO;

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
