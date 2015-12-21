//  Created by Monte Hurd on 2/10/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikipediaAppUtils.h"
#import "LoginViewController.h"
#import "QueuesSingleton.h"
#import "LoginTokenFetcher.h"
#import "AccountLogin.h"
#import "SessionSingleton.h"
#import "NSHTTPCookieStorage+CloneCookie.h"
#import "AccountCreationViewController.h"
#import "WMF_Colors.h"
#import "MenuButton.h"
#import "PaddedLabel.h"
#import "CreateAccountFunnel.h"
#import "PreviewAndSaveViewController.h"
#import "SectionEditorViewController.h"
#import "AccountCreationViewController.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIView+WMFRTLMirroring.h"
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"

@interface LoginViewController (){
}

@property (weak, nonatomic) IBOutlet UIScrollView* scrollView;
@property (weak, nonatomic) IBOutlet UITextField* usernameField;
@property (weak, nonatomic) IBOutlet UITextField* passwordField;
@property (weak, nonatomic) IBOutlet PaddedLabel* createAccountButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* usernameUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* passwordUnderlineHeight;
@property (weak, nonatomic) IBOutlet PaddedLabel* titleLabel;

@property (weak, nonatomic) IBOutlet UIView* loginContainerView;

@property (nonatomic, copy) void (^ successBlock)();
@property (nonatomic, copy) void (^ failBlock)();

@property (strong, nonatomic) UIBarButtonItem* doneButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.navigationController.navigationBar wmf_mirrorIfDeviceRTL];

    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItems = @[xButton];

    self.doneButton = [[UIBarButtonItem alloc] bk_initWithTitle:MWLocalizedString(@"button-done", nil) style:UIBarButtonItemStylePlain handler:^(id sender){
        @strongify(self)
        [self save];
    }];
    self.navigationItem.rightBarButtonItem = self.doneButton;

    self.successBlock = ^(){};
    self.failBlock = ^(){};

    self.titleLabel.font          = [UIFont boldSystemFontOfSize:23.0f * MENUS_SCALE_MULTIPLIER];
    self.usernameField.font       = [UIFont boldSystemFontOfSize:18.0f * MENUS_SCALE_MULTIPLIER];
    self.passwordField.font       = [UIFont boldSystemFontOfSize:18.0f * MENUS_SCALE_MULTIPLIER];
    self.createAccountButton.font = [UIFont boldSystemFontOfSize:14.0f * MENUS_SCALE_MULTIPLIER];

    self.createAccountButton.textColor              = WMF_COLOR_BLUE;
    self.createAccountButton.padding                = UIEdgeInsetsMake(10, 10, 10, 10);
    self.createAccountButton.text                   = MWLocalizedString(@"login-account-creation", nil);
    self.createAccountButton.userInteractionEnabled = YES;
    [self.createAccountButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(createAccountButtonPushed:)]];

    self.usernameField.attributedPlaceholder =
        [self getAttributedPlaceholderForString:MWLocalizedString(@"login-username-placeholder-text", nil)];
    self.passwordField.attributedPlaceholder =
        [self getAttributedPlaceholderForString:MWLocalizedString(@"login-password-placeholder-text", nil)];

    UILongPressGestureRecognizer* longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress)];
    longPressRecognizer.minimumPressDuration = 1.0f;
    [self.view addGestureRecognizer:longPressRecognizer];

    if ([self.scrollView respondsToSelector:@selector(keyboardDismissMode)]) {
        self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }

    [self.usernameField addTarget:self
                           action:@selector(textFieldDidChange:)
                 forControlEvents:UIControlEventEditingChanged];

    [self.passwordField addTarget:self
                           action:@selector(textFieldDidChange:)
                 forControlEvents:UIControlEventEditingChanged];

    self.usernameUnderlineHeight.constant = 1.0f / [UIScreen mainScreen].scale;
    self.passwordUnderlineHeight.constant = self.usernameUnderlineHeight.constant;

    self.titleLabel.text = MWLocalizedString(@"navbar-title-mode-login", nil);

    self.usernameField.textAlignment = NSTextAlignmentNatural;
    self.passwordField.textAlignment = NSTextAlignmentNatural;

    if (self.loginContainerView) {
        // Only do this if self.loginContainerView is not nil. This is because the
        // account areation view controller can create a "detached" instance of the
        // login view controller after it creates an account - which it uses to
        // login to the new account. (This detached object object won't have views
        // so the array below will cause a crash.)
        [self adjustConstraintsScaleForViews:
         @[
             self.loginContainerView,
             self.titleLabel,
             self.usernameField,
             self.passwordField,
             self.createAccountButton]
        ];
    }
}

- (NSAttributedString*)getAttributedPlaceholderForString:(NSString*)string {
    return [[NSMutableAttributedString alloc] initWithString:string
                                                  attributes:@{
                NSForegroundColorAttributeName: [UIColor lightGrayColor]
            }];
}

- (void)textFieldDidChange:(id)sender {
    BOOL shouldHighlight = ((self.usernameField.text.length > 0) && (self.passwordField.text.length > 0)) ? YES : NO;
    [self enableProgressiveButton:shouldHighlight];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self save];
    }
    return YES;
}

- (void)enableProgressiveButton:(BOOL)highlight {
    self.doneButton.enabled = highlight;
}

- (void)handleLongPress {
    // Uncomment for presentation username/pwd auto entry
    // self.usernameField.text = @"montehurd";
    // self.passwordField.text = @"";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self enableProgressiveButton:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.usernameField becomeFirstResponder];
}

- (void)save {
    [self enableProgressiveButton:NO];

    [self loginWithUserName:self.usernameField.text
                   password:self.passwordField.text
                  onSuccess:^{
        NSString* loggedInMessage = MWLocalizedString(@"main-menu-account-title-logged-in", nil);
        loggedInMessage = [loggedInMessage stringByReplacingOccurrencesOfString:@"$1"
                                                                     withString:self.usernameField.text];
        [[WMFAlertManager sharedInstance] showAlert:loggedInMessage sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];

        [self dismissViewControllerAnimated:YES completion:nil];
    } onFail:^{
        [self enableProgressiveButton:YES];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self enableProgressiveButton:NO];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if ([sender isKindOfClass:[LoginTokenFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                (void)[[AccountLogin alloc] initAndLoginForDomain:[sender domain]
                                                         userName:[sender userName]
                                                         password:[sender password]
                                                            token:[sender token]
                                                      withManager:[QueuesSingleton sharedInstance].loginFetchManager
                                               thenNotifyDelegate:self];
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:

                [[WMFAlertManager sharedInstance] dismissAlert];
                self.failBlock();

                break;
            case FETCH_FINAL_STATUS_FAILED:

                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
                self.failBlock();
                [self.funnel logError:error.localizedDescription];

                break;
        }
    }

    if ([sender isKindOfClass:[AccountLogin class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                //NSLog(@"%@", fetchedData);
                NSString* loginStatus = fetchedData[@"login"][@"result"];

                // Login credentials should only be placed in the keychain if they've been authenticated.
                NSString* normalizedUserName = fetchedData[@"login"][@"lgusername"];
                [SessionSingleton sharedInstance].keychainCredentials.userName = normalizedUserName;
                [SessionSingleton sharedInstance].keychainCredentials.password = fetchedData[@"password"];

                //NSString *result = loginResult[@"login"][@"result"];
                [[WMFAlertManager sharedInstance] showSuccessAlert:loginStatus sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];

                self.successBlock();

                [self cloneSessionCookies];
                //printCookies();

                [self.funnel logSuccess];
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:

                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
                self.failBlock();

                break;
            case FETCH_FINAL_STATUS_FAILED:

                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
                self.failBlock();
                [self.funnel logError:error.localizedDescription];

                break;
        }
    }
}

- (void)loginWithUserName:(NSString*)userName
                 password:(NSString*)password
                onSuccess:(void (^)(void))successBlock
                   onFail:(void (^)(void))failBlock {
    [[WMFAlertManager sharedInstance] dismissAlert];

    // Fix for iOS 6 crashing on empty credentials.
    if (!userName) {
        userName = @"";
    }
    if (!password) {
        password = @"";
    }

    self.successBlock = (!successBlock) ? ^(){} : successBlock;
    self.failBlock = (!failBlock) ? ^(){} : failBlock;

    /*
       void (^printCookies)() =  ^void(){
        NSLog(@"\n\n\n\n\n\n\n\n\n\n");
        for (NSHTTPCookie *cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
            NSLog(@"cookies = %@", cookie.properties);
        }
        NSLog(@"\n\n\n\n\n\n\n\n\n\n");
       };
     */

    //[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

    [[QueuesSingleton sharedInstance].loginFetchManager.operationQueue cancelAllOperations];
    (void)[[LoginTokenFetcher alloc] initAndFetchTokenForDomain:[SessionSingleton sharedInstance].currentArticleSite.language
                                                       userName:userName
                                                       password:password
                                                    withManager:[QueuesSingleton sharedInstance].loginFetchManager
                                             thenNotifyDelegate:self];
}

- (void)cloneSessionCookies {
    // Make the session cookies expire at same time user cookies. Just remember they still can't be
    // necessarily assumed to be valid as the server may expire them, but at least make them last as
    // long as we can to lessen number of server requests. Uses user tokens as templates for copying
    // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.

    NSString* domain = [SessionSingleton sharedInstance].currentArticleSite.language;

    NSString* cookie1Name = [NSString stringWithFormat:@"%@wikiSession", domain];
    NSString* cookie2Name = [NSString stringWithFormat:@"%@wikiUserID", domain];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] recreateCookie:cookie1Name
                                            usingCookieAsTemplate:cookie2Name
    ];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] recreateCookie:@"centralauth_Session"
                                            usingCookieAsTemplate:@"centralauth_User"
    ];
}

- (void)createAccountButtonPushed:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.funnel logCreateAccountAttempt];

        UIViewController* presenter = self.presentingViewController;
        [self dismissViewControllerAnimated:YES completion:^{
            AccountCreationViewController* createAcctVC = [AccountCreationViewController wmf_initialViewControllerFromClassStoryboard];

            createAcctVC.funnel = [[CreateAccountFunnel alloc] init];
            [createAcctVC.funnel logStartFromLogin:self.funnel.loginSessionToken];

            UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:createAcctVC];

            [presenter presentViewController:nc animated:YES completion:nil];
        }];
    }
}

@end
