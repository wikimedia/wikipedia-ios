//  Created by Monte Hurd on 2/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PreviewAndSaveViewController.h"
#import "WikipediaAppUtils.h"
#import "PreviewWikiTextOp.h"
#import "UIViewController+Alert.h"
#import "ArticleCoreDataObjects.h"
#import "ArticleDataContextSingleton.h"
#import "QueuesSingleton.h"
#import "CenterNavController.h"
#import "UploadSectionWikiTextOp.h"
#import "CaptchaViewController.h"
#import "UIViewController+HideKeyboard.h"
#import "EditTokenOp.h"
#import "SessionSingleton.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "PreviewWebView.h"
#import "LoginViewController.h"
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
#import "UIViewController+PresentModal.h"

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
@property (nonatomic) BOOL saveAutomaticallyIfSignedIn;
@property (weak, nonatomic) IBOutlet UIWebView *previewWebView;
@property (strong, nonatomic) CommunicationBridge *bridge;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewWebViewHeightConstraint;
@property (strong, nonatomic) UILabel *aboutLabel;
@property (strong, nonatomic) MenuButton *cannedSummary01;
@property (strong, nonatomic) MenuButton *cannedSummary02;
@property (strong, nonatomic) MenuButton *cannedSummary03;
@property (strong, nonatomic) MenuButton *cannedSummary04;
@property (nonatomic) CGFloat borderWidth;

@end

@implementation PreviewAndSaveViewController

-(NSString *)getSummary
{
    NSMutableArray *summaryArray = @[].mutableCopy;
    
    if (self.summaryText && (self.summaryText.length > 0)) {
        [summaryArray addObject:self.summaryText];
    }
    if (self.cannedSummary01.enabled) [summaryArray addObject:self.cannedSummary01.text];
    if (self.cannedSummary02.enabled) [summaryArray addObject:self.cannedSummary02.text];
    if (self.cannedSummary03.enabled) [summaryArray addObject:self.cannedSummary03.text];

    if (self.cannedSummary04.enabled) [summaryArray addObject:self.cannedSummary04.text];

    return [summaryArray componentsJoinedByString:@"; "];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)resetBridge
{
    self.bridge = [[CommunicationBridge alloc] initWithWebView: self.previewWebView
                                                  htmlFileName: @"preview.html"];

    [self.bridge addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {

    }];

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
            [ROOT popViewControllerAnimated:YES];
            
            if(ROOT.topMenuViewController.navBarMode == NAVBAR_MODE_EDIT_WIKITEXT_WARNING){
                [self.funnel logAbuseFilterWarningBack:@"fixme"]; // @fixme
            }
            
            break;
        case NAVBAR_BUTTON_SAVE: /* for captcha submit button */
        case NAVBAR_BUTTON_CHECK:
            {
                switch (ROOT.topMenuViewController.navBarMode) {
                    case NAVBAR_MODE_EDIT_WIKITEXT_WARNING:
                        [self save];
                        [self.funnel logAbuseFilterWarningIgnore:@"fixme"]; // @fixme
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
    
    self.saveAutomaticallyIfSignedIn = NO;
    
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
    
    NSArray *constraints = @[
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[aboutLabel]|" options:0 metrics:nil views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cannedSummary01]" options:0 metrics:nil views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cannedSummary02]" options:0 metrics:nil views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cannedSummary03]" options:0 metrics:nil views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cannedSummary04]" options:0 metrics:nil views:views],
        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(40)-[aboutLabel]-(5)-[cannedSummary01][cannedSummary02][cannedSummary03][cannedSummary04]-(50)-|" options:0 metrics:nil views:views]
    ];
    [self.editSummaryContainer addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

-(void)setupEditSummaryContainerSubviews
{
    // Setup the canned edit summary buttons.
    UIColor *color = [UIColor colorWithRed:0.03 green:0.48 blue:0.92 alpha:1.0];
    UIEdgeInsets padding = UIEdgeInsetsMake(6, 10, 6, 10);
    UIEdgeInsets margin = UIEdgeInsetsMake(8, 0, 8, 0);
    CGFloat fontSize = 14;
    
    MenuButton * (^setupButton)(NSString *, NSInteger) = ^MenuButton *(NSString *text, NSInteger tag) {
        MenuButton *button = [[MenuButton alloc] initWithText:text fontSize:fontSize color:color padding:padding margin:margin];
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
    self.aboutLabel.font = [UIFont boldSystemFontOfSize:24];
    self.aboutLabel.textColor = [UIColor darkGrayColor];
    self.aboutLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.aboutLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.aboutLabel.text = MWLocalizedString(@"edit-summary-title", nil);
    [self.editSummaryContainer addSubview:self.aboutLabel];
}

-(void)buttonTapped:(UIGestureRecognizer *)recognizer
{
    MenuButton *tappedButton = (MenuButton *)recognizer.view;
    switch (tappedButton.tag) {
        case CANNED_SUMMARY_OTHER:
            [self showSummaryOverlay];
            break;
            
        default:
            tappedButton.enabled = !tappedButton.enabled;
            
            break;
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

    [self saveAutomaticallyIfNecessary];

    // Highlight the "Other" button if the user entered some "other" text.
    self.cannedSummary04.enabled = (self.summaryText.length > 0) ? YES : NO;

    [super viewWillAppear:animated];
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

    [super viewWillDisappear:animated];
}

- (void)preview
{
    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    // Use static flag to prevent preview when preview already in progress.
    static BOOL isAleadyPreviewing = NO;
    if (isAleadyPreviewing) return;
    isAleadyPreviewing = YES;

    [self showAlert:MWLocalizedString(@"wikitext-preview-changes", nil)];
    Section *section = (Section *)[articleDataContext_.mainContext objectWithID:self.sectionID];

    PreviewWikiTextOp *previewWikiTextOp =
    [[PreviewWikiTextOp alloc] initWithDomain: section.article.domain
                                        title: section.article.title
                                     wikiText: self.wikiText
                              completionBlock: ^(NSString *result){

        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {

            [self fadeAlert];

            [self resetBridge];
            
            [self.bridge sendMessage:@"append" withPayload:@{@"html": result ? result : @""}];

            isAleadyPreviewing = NO;
            
        }];
        
    } cancelledBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        isAleadyPreviewing = NO;
        
    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        
        [self showAlert:errorMsg];
        
        isAleadyPreviewing = NO;
    }];

    previewWikiTextOp.delegate = self;

    [[QueuesSingleton sharedInstance].sectionWikiTextPreviewQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].sectionWikiTextPreviewQ addOperation:previewWikiTextOp];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

- (void)save
{
    NSString *editSummary = [self getSummary];

    // Use static flag to prevent save when save already in progress.
    static BOOL isAleadySaving = NO;
    if (isAleadySaving) return;
    isAleadySaving = YES;

    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    [self showAlert:MWLocalizedString(@"wikitext-upload-save", nil)];
    Section *section = (Section *)[articleDataContext_.mainContext objectWithID:self.sectionID];

    NSManagedObjectID *articleID = section.article.objectID;

    // If fromTitle was set, the section was transcluded, so use the title of the page
    // it was transcluded from.
    NSString *title = section.fromTitle ? section.fromTitle : section.article.title;

    UploadSectionWikiTextOp *uploadWikiTextOp =
    [[UploadSectionWikiTextOp alloc] initForPageTitle:title domain:section.article.domain section:section.index wikiText:self.wikiText summary:editSummary captchaId:self.captchaId captchaWord:self.captchaViewController.captchaTextBox.text  completionBlock:^(NSString *result){
        
        // Mark article for refreshing and reload it.
        if (articleID) {
            [self.funnel logSavedRevision:0]; // @fixme need revision ID
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                WebViewController *webVC = [self.navigationController searchNavStackForViewControllerOfClass:[WebViewController class]];
                [webVC reloadCurrentArticleInvalidatingCache:YES];
                [ROOT popToViewController:webVC animated:YES];
                isAleadySaving = NO;
            }];
        }

    } cancelledBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        isAleadySaving = NO;
        
    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        
        [self showAlert:errorMsg];

        switch (error.code) {
            case WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA:
            {

                if(ROOT.topMenuViewController.navBarMode == NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA){
                    [self.funnel logCaptchaFailure];
                }
            
                // If the server said a captcha was required, present the captcha image.
                NSString *captchaUrl = error.userInfo[@"captchaUrl"];
                NSString *captchaId = error.userInfo[@"captchaId"];
                if (articleID) {
                    [articleDataContext_.mainContext performBlockAndWait:^(){
                        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
                        if (article) {
                            [UIView animateWithDuration:0.2f animations:^{

                                [self revealCaptcha];

                                [self.captchaViewController.captchaTextBox performSelector: @selector(becomeFirstResponder)
                                                                                withObject: nil
                                                                                afterDelay: 0.4f];

                                [self.captchaViewController showAlert:errorMsg];

                                self.captchaViewController.captchaImageView.image = nil;

                                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                                    // Background thread.
                                    
                                    NSURL *captchaImageUrl = [NSURL URLWithString:
                                                              [NSString stringWithFormat:@"https://%@.m.%@%@", article.domain, article.site, captchaUrl]
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
                    }];
                }
            }
                break;
                
            case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED:
            case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING:
            case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER:
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    NSString *warningHtml = error.userInfo[@"warning"];
                    
                    [self hideKeyboard];
                    
                    NSString *bannerImage = nil;
                    UIColor *bannerColor = nil;
                    
                    if ((error.code == WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED)) {
                        ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW;
                        bannerImage = @"abuse-filter-disallowed.png";
                        bannerColor = WMF_COLOR_RED;

                        [self.funnel logAbuseFilterError: warningHtml]; // @fixme not sure this is right message

                    }else{
                        ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_WARNING;

                        //[self highlightProgressiveButtons:YES];

                        bannerImage = @"abuse-filter-flag-white.png";
                        bannerColor = WMF_COLOR_ORANGE;

                        [self.funnel logAbuseFilterWarning:warningHtml]; // @fixme not sure this is right message

                    }

                    // Hides the license panel. Needed if logged in and a disallow is triggered.
                    [self.navigationController topActionSheetHide];
                    
                    NSString *restyledWarningHtml = [self restyleAbuseFilterWarningHtml:warningHtml];
                    [self fadeAlert];
                    [self showHTMLAlert: restyledWarningHtml
                            bannerImage: [UIImage imageNamed:bannerImage]
                            bannerColor: bannerColor
                     ];
                });
            }
                break;

            case WIKITEXT_UPLOAD_ERROR_SERVER:
            case WIKITEXT_UPLOAD_ERROR_UNKNOWN:

                [self.funnel logError:error.localizedDescription]; // @fixme is this right msg?
                break;
                
            default:
                break;
        }
        isAleadySaving = NO;
    }];

    EditTokenOp *editTokenOp =
    [[EditTokenOp alloc] initWithDomain: section.article.domain
                        completionBlock: ^(NSDictionary *result){
                            //NSLog(@"editTokenOp result = %@", result);
                            //NSLog(@"editTokenOp result tokens = %@", result[@"tokens"][@"edittoken"]);

                            if (articleID) {
                                [articleDataContext_.mainContext performBlockAndWait:^(){
                                    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
                                    if (article) {
                                        NSString *editToken = result[@"tokens"][@"edittoken"];
                                        NSMutableDictionary *editTokens =
                                            [SessionSingleton sharedInstance].keychainCredentials.editTokens;
                                        //NSLog(@"article.domain = %@", article.domain);
                                        editTokens[article.domain] = editToken;
                                        [SessionSingleton sharedInstance].keychainCredentials.editTokens = editTokens;
                                    }
                                }];
                            }

                        } cancelledBlock: ^(NSError *error){
                            
                            [self fadeAlert];
                            
                            isAleadySaving = NO;
                            
                        } errorBlock: ^(NSError *error){
                            
                            [self showAlert:error.localizedDescription];
                            isAleadySaving = NO;
                            
                        }];

//TODO: if we have credentials, yet the edit token retrieved for an edit is
// an anonymous token (i think this happens if you try to get an edit token
// and your login session has expired), need to pop up alert asking user if they
// want to log in before continuing with their edit. In this scenario would
// probably need cancelDependentOpsIfThisOpFails set to YES, then if the user
// says they don't want to login in (ie continue anon editing) then we would
// want cancelDependentOpsIfThisOpFails set to NO.

    editTokenOp.delegate = self;
    uploadWikiTextOp.delegate = self;
    
    // Still try the uploadWikiTextOp even if editTokenOp fails to get a token. uploadWikiTextOp
    // will use an anonymous "+\" edit token if it doesn't find an edit token.
    editTokenOp.cancelDependentOpsIfThisOpFails = NO;
    
    // Try to get an edit token for the page's domain before trying to upload the changes.
    [uploadWikiTextOp addDependency:editTokenOp];
    
    [[QueuesSingleton sharedInstance].sectionWikiTextUploadQ cancelAllOperations];
    [QueuesSingleton sharedInstance].sectionWikiTextUploadQ.suspended = YES;
    
    [[QueuesSingleton sharedInstance].sectionWikiTextUploadQ addOperation:editTokenOp];
    [[QueuesSingleton sharedInstance].sectionWikiTextUploadQ addOperation:uploadWikiTextOp];
    
    [QueuesSingleton sharedInstance].sectionWikiTextUploadQ.suspended = NO;
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

//TODO: this shouldn't be in the controller. Find it a nice home.
-(NSString *)restyleAbuseFilterWarningHtml:(NSString *)warningHtml
{
    // Abuse filter warnings have html :( Re-style as best we can...
    return [NSString stringWithFormat:
        @"\
        <html>\
        <head>\
        <style>\
            *{\
                background-color:transparent!important;\
                border-color:transparent!important;\
                width:auto!important;\
                font:auto!important;\
                font-family:sans-serif!important;\
                font-size:14px!important;\
                color:rgb(85, 85, 85)!important;\
                line-height:22px!important;\
                text-align:left!important;\
            }\
            td[style]{background-color:transparent!important;border-style:none!important;}\
            IMG{zoom:0.5;margin:20px}\
            body{padding:21px!important;padding-top:16px!important;margin:0px!important;}\
        </style>\
        </head>\
        <body>\
        <div>\
            %@\
        </div>\
        </body>\
        </html>\
        ",
    warningHtml];
}

/*
save this and call it if the user taps the blue "Log In" text in the CC text
            self.saveAutomaticallyIfSignedIn = YES;
            LoginViewController *loginVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            loginVC.funnel = [[LoginFunnel alloc] init];
            [loginVC.funnel logStartFromEdit:self.funnel.editSessionToken];
            [ROOT pushViewController:loginVC animated:YES];



*/


/*
this save call was invoked when old sign-in/save-anon choice was presented and user selected save-anon.
question: does logSaveAnonExplicit need to be called - maybe in save method if not logged in? check it it already is
            [self.funnel logSaveAnonExplicit];

            [self save];
*/

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
