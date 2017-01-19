#import "AccountCreationViewController.h"
#import "SessionSingleton.h"
#import "UIScrollView+ScrollSubviewToLocation.h"
#import "LoginViewController.h"
#import "PreviewAndSaveViewController.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIViewController+WMFChildViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "SectionEditorViewController.h"
#import "Wikipedia-Swift.h"
#import "PaddedLabel.h"
#import "MWKLanguageLinkController.h"
#import "WMFAuthenticationManager.h"
#import <SDWebImage/SDWebImage.h>

@import BlocksKitUIKitExtensions;

@interface AccountCreationViewController ()

@property (strong, nonatomic) CaptchaViewController *captchaViewController;
@property (weak, nonatomic) IBOutlet UIView *captchaContainer;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) BOOL showCaptchaContainer;
@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) NSURL *captchaUrl;
@property (weak, nonatomic) IBOutlet PaddedLabel *loginButton;
@property (weak, nonatomic) IBOutlet PaddedLabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usernameUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordConfirmUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailUnderlineHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spaceBeneathCaptchaContainer;

@property (weak, nonatomic) IBOutlet UIView *createAccountContainerView;

@property (strong, nonatomic) UIBarButtonItem *rightButton;

@end

@implementation AccountCreationViewController

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Disable horizontal scrolling.
    scrollView.contentOffset = CGPointMake(0.0, scrollView.contentOffset.y);
}

- (void)updateViewConstraints {
    [self adjustScrollLimitForCaptchaVisiblity];

    [super updateViewConstraints];
}

- (void)adjustScrollLimitForCaptchaVisiblity {
    // Reminder: spaceBeneathCaptchaContainer constraint is space *below* captcha container - that's why below
    // for the show case we don't have to "convertPoint".
    self.spaceBeneathCaptchaContainer.constant =
        (self.showCaptchaContainer)
            ? (self.view.frame.size.height - (self.captchaContainer.frame.size.height / 2))
            : (self.view.frame.size.height - [self.loginButton convertPoint:CGPointZero toView:self.scrollView].y);
    ;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    // Ensure adjustScrollLimitForCaptchaVisiblity gets called again after rotating.
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    @weakify(self)
        UIBarButtonItem *xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX
                                                           handler:^(id sender) {
                                                               @strongify(self) if (self.showCaptchaContainer) {
                                                                   self.showCaptchaContainer = NO;
                                                               }
                                                               else {
                                                                   [self dismissViewControllerAnimated:YES completion:nil];
                                                               }
                                                           }];
    self.navigationItem.leftBarButtonItems = @[xButton];

    self.rightButton = [[UIBarButtonItem alloc] bk_initWithTitle:MWLocalizedString(@"button-next", nil)
                                                           style:UIBarButtonItemStylePlain
                                                         handler:^(id sender) {
                                                             @strongify(self)

                                                                 [[WMFAlertManager sharedInstance] showAlert:MWLocalizedString(@"account-creation-saving", nil)
                                                                                                      sticky:YES
                                                                                       dismissPreviousAlerts:YES
                                                                                                 tapCallBack:NULL];

                                                             [self save];
                                                         }];
    self.navigationItem.rightBarButtonItem = self.rightButton;

    self.titleLabel.font = [UIFont boldSystemFontOfSize:23.0f];
    self.usernameField.font = [UIFont boldSystemFontOfSize:18.0f];
    self.passwordField.font = [UIFont boldSystemFontOfSize:18.0f];
    self.passwordRepeatField.font = [UIFont boldSystemFontOfSize:18.0f];
    self.emailField.font = [UIFont boldSystemFontOfSize:18.0f];
    self.loginButton.font = [UIFont boldSystemFontOfSize:14.0f];

    self.captchaId = @"";
    self.captchaUrl = nil;
    self.scrollView.delegate = self;

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

    self.loginButton.textColor = [UIColor wmf_blueTintColor];
    self.loginButton.padding = UIEdgeInsetsMake(10, 10, 10, 10);
    self.loginButton.text = MWLocalizedString(@"account-creation-login", nil);
    self.loginButton.userInteractionEnabled = YES;
    [self.loginButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginButtonPushed:)]];

    self.titleLabel.text = MWLocalizedString(@"navbar-title-mode-create-account", nil);

    self.usernameField.textAlignment = NSTextAlignmentNatural;
    self.passwordField.textAlignment = NSTextAlignmentNatural;
    self.passwordRepeatField.textAlignment = NSTextAlignmentNatural;
    self.emailField.textAlignment = NSTextAlignmentNatural;
}

- (void)loginButtonPushed:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        UIViewController *presenter = self.presentingViewController;

        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                     UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:[LoginViewController wmf_initialViewControllerFromClassStoryboard]];

                                     [presenter presentViewController:nc animated:YES completion:nil];
                                 }];
    }
}

- (NSAttributedString *)getAttributedPlaceholderForString:(NSString *)string {
    return [[NSMutableAttributedString alloc] initWithString:string
                                                  attributes:@{
                                                      NSForegroundColorAttributeName: [UIColor lightGrayColor]
                                                  }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.captchaViewController = [CaptchaViewController wmf_initialViewControllerFromClassStoryboard];
    [self wmf_addChildController:self.captchaViewController andConstrainToEdgesOfContainerView:self.captchaContainer];

    self.showCaptchaContainer = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:@"UITextFieldTextDidChangeNotification"
                                               object:self.captchaViewController.captchaTextBox];

    [self enableProgressiveButton:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.usernameField becomeFirstResponder];
}

- (void)textFieldDidChange:(id)sender {
    BOOL shouldHighlight = ((self.usernameField.text.length > 0) &&
                            (self.passwordField.text.length > 0) &&
                            (self.passwordRepeatField.text.length > 0) &&
                            //(self.emailField.text.length > 0) &&
                            [self.passwordField.text isEqualToString:self.passwordRepeatField.text])
                               ? YES
                               : NO;

    // Override shouldHighlight if the text changed was the captcha field.
    if ([sender isKindOfClass:[NSNotification class]]) {
        NSNotification *notification = (NSNotification *)sender;
        if (notification.object == self.captchaViewController.captchaTextBox) {
            NSString *trimmedCaptchaText =
                [self.captchaViewController.captchaTextBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            shouldHighlight = (trimmedCaptchaText.length > 0) ? YES : NO;
        }
    }

    [self enableProgressiveButton:shouldHighlight];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self.passwordRepeatField becomeFirstResponder];
    } else if (textField == self.passwordRepeatField) {
        [self.emailField becomeFirstResponder];
    } else {
        NSAssert(((textField == self.emailField) || (textField == self.captchaViewController.captchaTextBox)),
                 @"Received -textFieldShouldReturn for unexpected text field: %@", textField);
        [self save];
    }
    return YES;
}

- (void)enableProgressiveButton:(BOOL)enabled {
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

- (void)prepopulateTextFieldsForDebugging {
#if DEBUG
    self.usernameField.text = @"acct_creation_test_010";
    self.passwordField.text = @"";
    self.passwordRepeatField.text = @"";
    self.emailField.text = @"mhurd@wikimedia.org";
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    [self enableProgressiveButton:NO];

    [[WMFAlertManager sharedInstance] dismissAlert];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UITextFieldTextDidChangeNotification"
                                                  object:self.captchaViewController.captchaTextBox];

    [super viewWillDisappear:animated];
}

- (void)setShowCaptchaContainer:(BOOL)showCaptchaContainer {
    _showCaptchaContainer = showCaptchaContainer;

    self.rightButton.title = showCaptchaContainer ? MWLocalizedString(@"button-done", nil) : MWLocalizedString(@"button-next", nil);

    CGFloat duration = 0.5;

    [self.view setNeedsUpdateConstraints];

    if (showCaptchaContainer) {
        [self.captchaViewController.captchaTextBox performSelector:@selector(becomeFirstResponder)
                                                        withObject:nil
                                                        afterDelay:0.4f];
        [self.funnel logCaptchaShown];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [UIView animateWithDuration:duration
                animations:^{
                    self.captchaContainer.alpha = 1;
                    [self.scrollView scrollSubViewToTop:self.captchaContainer animated:NO];
                }
                completion:^(BOOL done) {
                    [self enableProgressiveButton:NO];
                }];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[WMFAlertManager sharedInstance] dismissAlert];
            [UIView animateWithDuration:duration
                animations:^{
                    self.captchaContainer.alpha = 0;
                    [self.scrollView setContentOffset:CGPointZero animated:NO];
                }
                completion:^(BOOL done) {
                    self.captchaViewController.captchaTextBox.text = @"";
                    self.captchaViewController.captchaImageView.image = nil;
                    // Pretent a text field changed so the progressive button state gets updated.
                    [self textFieldDidChange:nil];
                }];
        });
    }
}

- (void)setCaptchaUrl:(NSURL *)captchaUrl {
    if (![_captchaUrl isEqual:captchaUrl]) {
        _captchaUrl = captchaUrl;
        if (captchaUrl) {
            [self refreshCaptchaImage];
        }
    }
}

- (void)refreshCaptchaImage {
    self.captchaViewController.captchaTextBox.text = @"";
    [self.captchaViewController.captchaImageView sd_setImageWithURL:self.captchaUrl];
    self.showCaptchaContainer = YES;
}

- (void)reloadCaptchaPushed:(id)sender {
    self.captchaViewController.captchaTextBox.text = @"";

    [[WMFAlertManager sharedInstance] showAlert:MWLocalizedString(@"account-creation-captcha-obtaining", nil) sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];

    [self save]; //this resarts the token process which gets us another captcha
}

- (void)login {
    [[WMFAlertManager sharedInstance] showAlert:MWLocalizedString(@"account-creation-logging-in", nil) sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
    [[WMFAuthenticationManager sharedInstance] loginWithUsername:self.usernameField.text
        password:self.passwordField.text
        success:^{
            NSString *loggedInMessage = MWLocalizedString(@"main-menu-account-title-logged-in", nil);
            loggedInMessage = [loggedInMessage stringByReplacingOccurrencesOfString:@"$1"
                                                                         withString:self.usernameField.text];
            [[WMFAlertManager sharedInstance] showSuccessAlert:loggedInMessage sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        failure:^(NSError *error) {
            [self enableProgressiveButton:YES];
        }];
}

- (NSArray *)requiredInputFields {
    NSAssert([self isViewLoaded],
             @"This method is only intended to be called when view is loaded, since they'll all be nil otherwise");
    return @[self.usernameField, self.passwordField, self.passwordRepeatField];
}

- (BOOL)isPasswordConfirmationCorrect {
    return [self.passwordField.text isEqualToString:self.passwordRepeatField.text];
}

- (BOOL)areRequiredFieldsPopulated {
    return NSNotFound ==
           [[self requiredInputFields] indexOfObjectPassingTest:^BOOL(UITextField *field, NSUInteger idx, BOOL *stop) {
               if (field.text.length == 0) {
                   *stop = YES;
                   return YES;
               } else {
                   return NO;
               }
           }];
}

- (void)save {
    if (![self areRequiredFieldsPopulated]) {
        [[WMFAlertManager sharedInstance] showErrorAlertWithMessage:MWLocalizedString(@"account-creation-missing-fields", nil) sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
        return;
    }

    // Verify passwords fields match.
    if (![self isPasswordConfirmationCorrect]) {
        [[WMFAlertManager sharedInstance] showErrorAlertWithMessage:MWLocalizedString(@"account-creation-passwords-mismatched", nil) sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
        return;
    }

    if ([self.captchaViewController.captchaTextBox.text length] == 0) {
        [[WMFAuthenticationManager sharedInstance] getAccountCreationCaptchaWithUsername:self.usernameField.text
            password:self.passwordField.text
            email:self.emailField.text
            captcha:^(NSURL *_Nonnull captchaURL) {
                self.captchaUrl = captchaURL;

                [[WMFAlertManager sharedInstance] showWarningAlert:MWLocalizedString(@"account-creation-captcha-required", nil) sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
            }
            failure:^(NSError *error) {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
                [self.funnel logError:error.localizedDescription];
            }];
    } else {
        [[WMFAuthenticationManager sharedInstance] createAccountWithCaptchaText:self.captchaViewController.captchaTextBox.text
            success:^{
                NSString *loggedInMessage = MWLocalizedString(@"main-menu-account-title-logged-in", nil);
                loggedInMessage = [loggedInMessage stringByReplacingOccurrencesOfString:@"$1"
                                                                             withString:self.usernameField.text];
                [[WMFAlertManager sharedInstance] showSuccessAlert:loggedInMessage sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            captcha:^(NSURL *_Nonnull captchaURL) {
                self.captchaUrl = captchaURL;

                [[WMFAlertManager sharedInstance] showWarningAlert:MWLocalizedString(@"account-creation-captcha-required", nil) sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
            }
            failure:^(NSError *error) {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
                [self.funnel logError:error.localizedDescription];
                [self enableProgressiveButton:YES];
            }];
    }
}

@end
