//  Created by Monte Hurd on 2/27/14.

#import "PreviewAndSaveViewController.h"
#import "PreviewWikiTextOp.h"
#import "UIViewController+Alert.h"
#import "ArticleCoreDataObjects.h"
#import "ArticleDataContextSingleton.h"
#import "QueuesSingleton.h"
#import "NavController.h"
#import "UIButton+ColorMask.h"
#import "UploadSectionWikiTextOp.h"
#import "CaptchaViewController.h"
#import "UIViewController+HideKeyboard.h"
#import "EditTokenOp.h"
#import "SessionSingleton.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "PreviewWebView.h"

#define NAV ((NavController *)self.navigationController)

@interface PreviewAndSaveViewController ()

@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) CaptchaViewController *captchaViewController;

@end

@implementation PreviewAndSaveViewController

// Handle nav bar taps.
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_ARROW_LEFT:
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case NAVBAR_BUTTON_CHECK:
        case NAVBAR_BUTTON_ARROW_RIGHT: /* for captcha submit button */
            {
                [self save];
            }
            break;
        default:
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.captchaId = @"";

    self.navigationItem.hidesBackButton = YES;

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(htmlAlertWasHidden)
                                                 name: @"HtmlAlertWasHidden"
                                               object: nil];
}

-(void)htmlAlertWasHidden
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];

    [self highlightArrowButton:YES];
   
    [self preview];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.scrollView.alpha = 0.0f;

    // Change the nav bar layout.
    NAV.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW;

    [super viewWillAppear:animated];
}

-(void)highlightArrowButton:(BOOL)highlight
{
    static BOOL lastHightlight = NO;
    if (lastHightlight == highlight) return;
    lastHightlight = highlight;

    UIButton *button = (UIButton *)[NAV getNavBarItem:NAVBAR_BUTTON_CHECK];

    button.backgroundColor = highlight ?
        [UIColor colorWithRed:0.24 green:0.41 blue:0.69 alpha:1.0]
        :
        [UIColor clearColor];
    
    [button maskButtonImageWithColor: highlight ?
        [UIColor whiteColor]
        :
        [UIColor blackColor]
     ];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [self showAlert:@""];

    // Change the nav bar layout.
    NAV.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT;

    [self highlightArrowButton:NO];

    [super viewWillDisappear:animated];
}

- (void)preview
{
    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    // Use static flag to prevent preview when preview already in progress.
    static BOOL isAleadyPreviewing = NO;
    if (isAleadyPreviewing) return;
    isAleadyPreviewing = YES;

    [self showAlert:NSLocalizedString(@"wikitext-preview-changes", nil)];
    Section *section = (Section *)[articleDataContext_.mainContext objectWithID:self.sectionID];

    PreviewWikiTextOp *previewWikiTextOp =
    [[PreviewWikiTextOp alloc] initWithDomain: section.article.domain
                                        title: section.article.title
                                     wikiText: self.wikiText
                              completionBlock: ^(NSString *result){

        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {

            [self showAlert:@""];

            NSURL *baseUrl = [[SessionSingleton sharedInstance] urlForDomain:[SessionSingleton sharedInstance].currentArticleDomain];
            
            [self.previewWebView loadHTMLString:result baseURL:baseUrl];

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

- (void)save
{
    // Use static flag to prevent save when save already in progress.
    static BOOL isAleadySaving = NO;
    if (isAleadySaving) return;
    isAleadySaving = YES;

    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    [self showAlert:NSLocalizedString(@"wikitext-upload-save", nil)];
    Section *section = (Section *)[articleDataContext_.mainContext objectWithID:self.sectionID];

    NSManagedObjectID *articleID = section.article.objectID;

    UploadSectionWikiTextOp *uploadWikiTextOp =
    [[UploadSectionWikiTextOp alloc] initForPageTitle:section.article.title domain:section.article.domain section:section.index wikiText:self.wikiText captchaId:self.captchaId captchaWord:self.captchaViewController.captchaTextBox.text  completionBlock:^(NSString *result){
        
        // Mark article for refreshing so its data will be reloaded.
        // (Needs to be done on worker context as worker context changes bubble up through
        // main context too - so web view controller accessing main context will see changes.)
        if (articleID) {
            [articleDataContext_.workerContext performBlockAndWait:^(){
                Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
                if (article) {
                    article.needsRefresh = @YES;
                    NSError *error = nil;
                    [articleDataContext_.workerContext save:&error];
                    NSLog(@"error = %@", error);
                }
            }];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {

            // Cause the web view to reload - now that its sections are gone it will try to reload them.

            WebViewController *webVC = [self.navigationController searchNavStackForViewControllerOfClass:[WebViewController class]];

            [self.navigationController popToViewController:webVC animated:YES];
            
            isAleadySaving = NO;
            
        }];
        
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
                        NAV.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW;
                        bannerImage = @"abuse-filter-disallowed.png";
                        bannerColor = [UIColor colorWithRed:0.93 green:0.18 blue:0.20 alpha:1.0];
                    }else{
                        NAV.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_WARNING;
                        bannerImage = @"abuse-filter-flag-white.png";
                        bannerColor = [UIColor colorWithRed:0.99 green:0.32 blue:0.22 alpha:1.0];
                    }
                    
                    NSString *restyledWarningHtml = [self restyleAbuseFilterWarningHtml:warningHtml];
                    [self showAlert:@""];
                    [self showHTMLAlert: restyledWarningHtml
                            bannerImage: [UIImage imageNamed:bannerImage]
                            bannerColor: bannerColor
                     ];
                });
            }
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
                            
                            NSString *editToken = result[@"tokens"][@"edittoken"];
                            NSMutableDictionary *editTokens = [SessionSingleton sharedInstance].keychainCredentials.editTokens;
                            editTokens[[SessionSingleton sharedInstance].domain] = editToken;
                            [SessionSingleton sharedInstance].keychainCredentials.editTokens = editTokens;
                            
                        } cancelledBlock: ^(NSError *error){
                            
                            [self showAlert:@""];
                            
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
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.35];
    [UIView setAnimationTransition: UIViewAnimationTransitionNone
                           forView: self.view
                             cache: NO];
    
    [self.view bringSubviewToFront:self.scrollView];
    
    self.scrollView.alpha = 1.0f;
    self.scrollView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.98];

    self.scrollContainer.backgroundColor = [UIColor clearColor];
    self.captchaContainer.backgroundColor = [UIColor clearColor];
    
    [UIView commitAnimations];
    
    NAV.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA;
    
    [self highlightCaptchaSubmitButton:NO];

    [self.captchaViewController.captchaTextBox addTarget: self
                                                  action: @selector(captchaTextFieldDidChange:)
                                        forControlEvents: UIControlEventEditingChanged];
}

-(void)captchaTextFieldDidChange:(id)sender
{
    [self highlightCaptchaSubmitButton:YES];
}

-(void)highlightCaptchaSubmitButton:(BOOL)highlight
{
    UIButton *button = (UIButton *)[NAV getNavBarItem:NAVBAR_BUTTON_ARROW_RIGHT];

    button.backgroundColor = highlight ?
        [UIColor colorWithRed:0.00 green:0.69 blue:0.54 alpha:1.0]
        :
        [UIColor clearColor];
    
    [button maskButtonImageWithColor: highlight ?
        [UIColor whiteColor]
        :
        [UIColor blackColor]
     ];
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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
