//  Created by Monte Hurd on 2/21/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AccountCreationViewController.h"
#import "WikipediaAppUtils.h"
#import "CenterNavController.h"
#import "QueuesSingleton.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
#import "AccountCreationTokenFetcher.h"
#import "AccountCreator.h"
#import "CaptchaResetter.h"
#import "UIScrollView+ScrollSubviewToLocation.h"
#import "LoginViewController.h"
#import "WMF_Colors.h"
#import "MenuButton.h"
#import "PaddedLabel.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "PreviewAndSaveViewController.h"
#import "OnboardingViewController.h"
#import "ModalMenuAndContentViewController.h"
#import "ModalContentViewController.h"
#import "UIViewController+ModalPresent.h"
#import "UIViewController+ModalsSearch.h"
#import "UIViewController+ModalPop.h"
#import "Defines.h"
#import "UIView+Debugging.h"
#import "NSObject+ConstraintsScale.h"

@interface AccountCreationViewController ()

@property (strong, nonatomic) CaptchaViewController *captchaViewController;
@property (weak, nonatomic) IBOutlet UIView *captchaContainer;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) BOOL showCaptchaContainer;
@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) NSString *captchaUrl;
@property (weak, nonatomic) IBOutlet PaddedLabel *loginButton;
@property (weak, nonatomic) IBOutlet PaddedLabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usernameUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordConfirmUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spaceBeneathCaptchaContainer;

@property (weak, nonatomic) IBOutlet UIView *createAccountContainerView;

@property (strong, nonatomic) LoginViewController *detachedloginVC;

@end

@implementation AccountCreationViewController

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_CREATE_ACCOUNT;
}

- (BOOL)prefersStatusBarHidden
{
    return NAV.isEditorOnNavstack;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Disable horizontal scrolling.
    scrollView.contentOffset = CGPointMake(0.0, scrollView.contentOffset.y);
}

-(void)updateViewConstraints
{
    [self adjustScrollLimitForCaptchaVisiblity];

    [super updateViewConstraints];
}

-(void)adjustScrollLimitForCaptchaVisiblity
{
    // Reminder: spaceBeneathCaptchaContainer constraint is space *below* captcha container - that's why below
    // for the show case we don't have to "convertPoint".
    self.spaceBeneathCaptchaContainer.constant =
        (self.showCaptchaContainer)
        ?
        (self.view.frame.size.height - (self.captchaContainer.frame.size.height / 2))
        :
        (self.view.frame.size.height - [self.loginButton convertPoint:CGPointZero toView:self.scrollView].y) ;
        ;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Ensure adjustScrollLimitForCaptchaVisiblity gets called again after rotating.
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.titleLabel.font = [UIFont boldSystemFontOfSize:23.0f * MENUS_SCALE_MULTIPLIER];
    self.usernameField.font = [UIFont boldSystemFontOfSize:18.0f * MENUS_SCALE_MULTIPLIER];
    self.passwordField.font = [UIFont boldSystemFontOfSize:18.0f * MENUS_SCALE_MULTIPLIER];
    self.passwordRepeatField.font = [UIFont boldSystemFontOfSize:18.0f * MENUS_SCALE_MULTIPLIER];
    self.emailField.font = [UIFont boldSystemFontOfSize:18.0f * MENUS_SCALE_MULTIPLIER];
    self.loginButton.font = [UIFont boldSystemFontOfSize:14.0f * MENUS_SCALE_MULTIPLIER];

    [self adjustConstraintsScaleForViews:@[self.createAccountContainerView, self.captchaContainer, self.titleLabel, self.usernameField, self.passwordField, self.passwordRepeatField, self.emailField, self.loginButton]];

    self.captchaId = @"";
    self.captchaUrl = @"";
    self.scrollView.delegate = self;
    self.navigationItem.hidesBackButton = YES;
    
    [self.usernameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.passwordRepeatField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.emailField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.captchaContainer.alpha = 0;

    self.usernameField.attributedPlaceholder =
        [self getAttributedPlaceholderForString:MWLocalizedString(@"account-creation-username-placeholder-text", nil)];

    self.passwordField.attributedPlaceholder =
        [self getAttributedPlaceholderForString:MWLocalizedString(@"account-creation-password-placeholder-text", nil)];

    self.passwordRepeatField.attributedPlaceholder =
        [self getAttributedPlaceholderForString:MWLocalizedString(@"account-creation-password-confirm-placeholder-text", nil)];

    self.emailField.attributedPlaceholder =
        [self getAttributedPlaceholderForString:MWLocalizedString(@"account-creation-email-placeholder-text", nil)];

    if ([self.scrollView respondsToSelector:@selector(keyboardDismissMode)]) {
        self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }

    self.usernameUnderlineHeight.constant = 1.0f / [UIScreen mainScreen].scale;
    self.passwordUnderlineHeight.constant = self.usernameUnderlineHeight.constant;
    self.passwordConfirmUnderlineHeight.constant = self.usernameUnderlineHeight.constant;
    self.emailUnderlineHeight.constant = self.usernameUnderlineHeight.constant;
    
    self.loginButton.textColor = WMF_COLOR_BLUE;
    self.loginButton.padding = UIEdgeInsetsMake(10, 10, 10, 10);
    self.loginButton.text = MWLocalizedString(@"account-creation-login", nil);
    self.loginButton.userInteractionEnabled = YES;
    [self.loginButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginButtonPushed:)]];
    
    // Hide the login button if the LoginViewController is on modal stack.
    self.loginButton.hidden = [self searchModalsForViewControllerOfClass:[LoginViewController class]] ? YES : NO;
    
    /*
    id previewAndSaveVC = [self searchModalsForViewControllerOfClass:[PreviewAndSaveViewController class]];
    self.titleLabel.text = (!previewAndSaveVC) ?
        MWLocalizedString(@"navbar-title-mode-create-account", nil)
        :
        MWLocalizedString(@"navbar-title-mode-create-account-and-save", nil)
    ;
    */
    
    self.titleLabel.text = MWLocalizedString(@"navbar-title-mode-create-account", nil);

    ((MenuButton *)[self.topMenuViewController getNavBarItem:NAVBAR_BUTTON_NEXT]).color = WMF_COLOR_GREEN;
    ((MenuButton *)[self.topMenuViewController getNavBarItem:NAVBAR_BUTTON_DONE]).color = WMF_COLOR_GREEN;

    self.usernameField.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    self.passwordField.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    self.passwordRepeatField.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    self.emailField.textAlignment = [WikipediaAppUtils rtlSafeAlignment];

    //[self.view randomlyColorSubviews];
}

- (void)loginButtonPushed:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self performModalSequeWithID: @"modal_segue_show_login"
                      transitionStyle: UIModalTransitionStyleCoverVertical
                                block: nil];
    }
}

-(NSAttributedString *)getAttributedPlaceholderForString:(NSString *)string
{
    return [[NSMutableAttributedString alloc] initWithString: string
                                                  attributes: @{
                                                               NSForegroundColorAttributeName : [UIColor lightGrayColor]
                                                               }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.showCaptchaContainer = NO;

    self.topMenuViewController.navBarMode = NAVBAR_MODE_CREATE_ACCOUNT;

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(textFieldDidChange:)
                                                 name: @"UITextFieldTextDidChangeNotification"
                                               object: self.captchaViewController.captchaTextBox];

    [self highlightProgressiveButton:NO];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navItemTappedNotification:) name:@"NavItemTapped" object:nil];
    
    [self.usernameField becomeFirstResponder];

    //[self prepopulateTextFieldsForDebugging];
}

-(void)textFieldDidChange:(id)sender
{
    BOOL shouldHighlight = (
        (self.usernameField.text.length > 0) &&
        (self.passwordField.text.length > 0) &&
        (self.passwordRepeatField.text.length > 0) &&
        //(self.emailField.text.length > 0) &&
        [self.passwordField.text isEqualToString:self.passwordRepeatField.text]
    ) ? YES : NO;

    // Override shouldHighlight if the text changed was the captcha field.
    if([sender isKindOfClass:[NSNotification class]]){
        NSNotification *notification = (NSNotification *)sender;
        if(notification.object == self.captchaViewController.captchaTextBox)
        {
            NSString *trimmedCaptchaText =
            [self.captchaViewController.captchaTextBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            shouldHighlight = (trimmedCaptchaText.length > 0) ? YES : NO;
        }
    }

    [self highlightProgressiveButton:shouldHighlight];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    }else if(textField == self.passwordField) {
        [self.passwordRepeatField becomeFirstResponder];
    }else if(textField == self.passwordRepeatField) {
        [self.emailField becomeFirstResponder];
    }else if((textField == self.emailField) || (textField == self.captchaViewController.captchaTextBox)) {
        [self save];
    }
    return YES;
}

-(void)highlightProgressiveButton:(BOOL)highlight
{
    ((MenuButton *)[self.topMenuViewController getNavBarItem:NAVBAR_BUTTON_DONE]).enabled = highlight;
    ((MenuButton *)[self.topMenuViewController getNavBarItem:NAVBAR_BUTTON_NEXT]).enabled = highlight;
}

-(void)prepopulateTextFieldsForDebugging
{
    self.usernameField.text = @"acct_creation_test_010";
    self.passwordField.text = @"";
    self.passwordRepeatField.text = @"";
    self.emailField.text = @"mhurd@wikimedia.org";
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NavItemTapped" object:nil];

    [self highlightProgressiveButton:NO];

    [self fadeAlert];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"UITextFieldTextDidChangeNotification"
                                                  object: self.captchaViewController.captchaTextBox];

    [super viewWillDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"AccountCreation_Captcha_Embed"]) {
		self.captchaViewController = (CaptchaViewController *) [segue destinationViewController];
	}
}

-(void)setShowCaptchaContainer:(BOOL)showCaptchaContainer
{
    _showCaptchaContainer = showCaptchaContainer;

    self.topMenuViewController.navBarMode = showCaptchaContainer ? NAVBAR_MODE_CREATE_ACCOUNT_CAPTCHA : NAVBAR_MODE_CREATE_ACCOUNT;

    CGFloat duration = 0.5;

    [self.view setNeedsUpdateConstraints];

    if(showCaptchaContainer){

        [self.captchaViewController.captchaTextBox performSelector: @selector(becomeFirstResponder)
                                                        withObject: nil afterDelay:0.4f];
        [self.funnel logCaptchaShown];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:duration animations:^{
                self.captchaContainer.alpha = 1;
                [self.scrollView scrollSubViewToTop:self.captchaContainer animated:NO];
            } completion:^(BOOL done){
                [self highlightProgressiveButton:NO];
            }];
        });
        
    }else{
    
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self fadeAlert];
            [UIView animateWithDuration:duration animations:^{
                self.captchaContainer.alpha = 0;
                [self.scrollView setContentOffset:CGPointZero animated:NO];
            } completion:^(BOOL done){
                self.captchaViewController.captchaTextBox.text = @"";
                self.captchaViewController.captchaImageView.image = nil;
                // Pretent a text field changed so the progressive button state gets updated.
                [self textFieldDidChange:nil];
            }];
        });

    }
}

-(void)setCaptchaUrl:(NSString *)captchaUrl
{
    if (![_captchaUrl isEqualToString:captchaUrl]) {
        _captchaUrl = captchaUrl;
        if (captchaUrl && (captchaUrl.length > 0)) {
            [self refreshCaptchaImage];
        }
    }
}

-(void)refreshCaptchaImage
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        // Background thread
        NSURL *captchaImageUrl = [NSURL URLWithString:
                                  [NSString stringWithFormat:@"https://%@.m.%@%@",
                                   [SessionSingleton sharedInstance].site.language,
                                   [SessionSingleton sharedInstance].site.domain,
                                   self.captchaUrl
                                   ]
                                  ];
        
        UIImage *captchaImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:captchaImageUrl]];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            // Main thread
            self.captchaViewController.captchaTextBox.text = @"";
            self.captchaViewController.captchaImageView.image = captchaImage;
            self.showCaptchaContainer = YES;
            //[self highlightCheckButton:NO];
        });
    });
}

- (void)reloadCaptchaPushed:(id)sender
{
    self.captchaViewController.captchaTextBox.text = @"";

    [self showAlert:MWLocalizedString(@"account-creation-captcha-obtaining", nil) type:ALERT_TYPE_TOP duration:1];

    [[QueuesSingleton sharedInstance].accountCreationFetchManager.operationQueue cancelAllOperations];
    
    (void)[[CaptchaResetter alloc] initAndResetCaptchaForDomain: [SessionSingleton sharedInstance].site.language
                                                    withManager: [QueuesSingleton sharedInstance].accountCreationFetchManager
                                             thenNotifyDelegate: self];
}

// Handle nav bar taps.
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_NEXT:
        case NAVBAR_BUTTON_DONE:
            [self save];
            break;
        case NAVBAR_BUTTON_X:
        case NAVBAR_BUTTON_ARROW_LEFT:
        {
            if (self.showCaptchaContainer) {
                self.showCaptchaContainer = NO;
            }else{
                [self popModal];
            }
        }
            break;
        default:
            break;
    }
}

-(void)login
{
    // Create detached loginVC just for logging in.
    self.detachedloginVC = [[LoginViewController alloc] init];
    
    [self showAlert:MWLocalizedString(@"account-creation-logging-in", nil) type:ALERT_TYPE_TOP duration:-1];
    
    [self.detachedloginVC loginWithUserName:self.usernameField.text password:self.passwordField.text onSuccess:^{

        NSString *loggedInMessage = MWLocalizedString(@"main-menu-account-title-logged-in", nil);
        loggedInMessage = [loggedInMessage stringByReplacingOccurrencesOfString: @"$1"
                                                                     withString: self.usernameField.text];
        [self showAlert:loggedInMessage type:ALERT_TYPE_TOP duration:-1];

        id onboardingVC = [self searchModalsForViewControllerOfClass:[OnboardingViewController class]];

        if (onboardingVC) {
            [self popModalToRoot];
        }else{
            [self.truePresentingVC popModal];
        }

    } onFail:^(){

        [self performSelector:@selector(popModal) withObject:nil afterDelay:0.5f];

    }];
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[AccountCreationTokenFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
                //NSLog(@"fetchedData = %@", fetchedData);
                // Pull data for all the fields which were originally passed to the token
                // fetcher from the fetchedData returned from it. This is to make extra sure
                // the account creation is working with the same data as the token retrieval.
                (void)[[AccountCreator alloc] initAndCreateAccountForUserName: [sender userName]
                                                                             realName: @""
                                                                               domain: [sender domain]
                                                                             password: [sender password]
                                                                                email: [sender email]
                                                                            captchaId: self.captchaId
                                                                          captchaWord: self.captchaViewController.captchaTextBox.text
                                                                                token: [sender token]
                                                                          withManager: [QueuesSingleton sharedInstance].accountCreationFetchManager
                                                                   thenNotifyDelegate: self];
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;
            case FETCH_FINAL_STATUS_FAILED:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                [self.funnel logError:error.localizedDescription];
                break;
        }
    }

    if ([sender isKindOfClass:[AccountCreator class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
                [self.funnel logSuccess];
                [self showAlert:fetchedData type:ALERT_TYPE_TOP duration:1];
                [self performSelector:@selector(login) withObject:nil afterDelay:0.6f];
                //isAleadySaving = NO;
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;
            case FETCH_FINAL_STATUS_FAILED:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                [self.funnel logError:error.localizedDescription];

                if (error.code == ACCOUNT_CREATION_ERROR_NEEDS_CAPTCHA) {
                    self.captchaId = error.userInfo[@"captchaId"];
                    self.captchaUrl = error.userInfo[@"captchaUrl"];
                    self.showCaptchaContainer = YES;
                }
                break;
        }
    }

    if ([sender isKindOfClass:[CaptchaResetter class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                
                self.captchaId = fetchedData[@"index"];
                
                NSString *oldCaptchaUrl = self.captchaUrl;
                
                NSError *error = nil;
                NSRegularExpression *regex =
                [NSRegularExpression regularExpressionWithPattern: @"wpCaptchaId=([^&]*)"
                                                          options: NSRegularExpressionCaseInsensitive
                                                            error: &error];
                if (!error) {
                    NSString *newCaptchaUrl =
                    [regex stringByReplacingMatchesInString: oldCaptchaUrl
                                                    options: 0
                                                      range: NSMakeRange(0, [oldCaptchaUrl length])
                                               withTemplate: [NSString stringWithFormat:@"wpCaptchaId=%@", self.captchaId]];
                    
                    self.captchaUrl = newCaptchaUrl;
                }
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;
            case FETCH_FINAL_STATUS_FAILED:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    }
}

-(void)save
{
    // Verify passwords fields match.
    if (![self.passwordField.text isEqualToString:self.passwordRepeatField.text]) {
        [self showAlert:MWLocalizedString(@"account-creation-passwords-mismatched", nil) type:ALERT_TYPE_TOP duration:-1];
        return;
    }

    // Save!
    [self showAlert:MWLocalizedString(@"account-creation-saving", nil) type:ALERT_TYPE_TOP duration:-1];

    [[QueuesSingleton sharedInstance].accountCreationFetchManager.operationQueue cancelAllOperations];

    (void)[[AccountCreationTokenFetcher alloc] initAndFetchTokenForDomain: [SessionSingleton sharedInstance].site.language
                                                                 userName: self.usernameField.text
                                                                 password: self.passwordField.text
                                                                    email: self.emailField.text
                                                              withManager: [QueuesSingleton sharedInstance].accountCreationFetchManager
                                                       thenNotifyDelegate: self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
