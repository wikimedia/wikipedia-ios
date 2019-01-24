#import "EditSaveViewController.h"
#import "WikiTextSectionUploader.h"
#import <WMF/SessionSingleton.h>
#import "AbuseFilterAlert.h"
#import "SavedPagesFunnel.h"
#import "EditFunnel.h"
#import "Wikipedia-Swift.h"
#import <WMF/AFHTTPSessionManager+WMFCancelAll.h>
#import "UIViewController+WMFOpenExternalUrl.h"

typedef NS_ENUM(NSInteger, WMFPreviewAndSaveMode) {
    PREVIEW_MODE_EDIT_WIKITEXT,
    PREVIEW_MODE_EDIT_WIKITEXT_WARNING,
    PREVIEW_MODE_EDIT_WIKITEXT_DISALLOW,
    PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW,
    PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA
};

@interface EditSaveViewController () <FetchFinishedDelegate, UITextFieldDelegate, UIScrollViewDelegate, PreviewLicenseViewDelegate, WMFCaptchaViewControllerDelegate, EditSummaryViewDelegate>

@property (strong, nonatomic) WMFCaptchaViewController *captchaViewController;
@property (strong, nonatomic) IBOutlet UIView *captchaContainer;

@property (strong, nonatomic) IBOutlet UIView *editSummaryVCContainer;

@property (strong, nonatomic) IBOutlet UIScrollView *captchaScrollView;
@property (strong, nonatomic) IBOutlet UIView *captchaScrollContainer;

@property (nonatomic) CGFloat borderWidth;
@property (strong, nonatomic) IBOutlet PreviewLicenseView *previewLicenseView;
@property (strong, nonatomic) UIGestureRecognizer *previewLicenseTapGestureRecognizer;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *scrollContainer;
@property (strong, nonatomic) UIBarButtonItem *buttonSave;
@property (strong, nonatomic) UIBarButtonItem *buttonNext;
@property (strong, nonatomic) UIBarButtonItem *buttonX;
@property (strong, nonatomic) UIBarButtonItem *buttonLeftCaret;
@property (strong, nonatomic) NSString *abuseFilterCode;

@property (strong, nonatomic) NSString *summaryText;

@property (strong, nonatomic) IBOutlet EditSummaryViewController *editSummaryViewController;

//@property (nonatomic) BOOL saveAutomaticallyIfSignedIn;

@property (nonatomic) WMFPreviewAndSaveMode mode;

@property (strong, nonatomic) WikiTextSectionUploader *wikiTextSectionUploader;
@property (strong, nonatomic) WMFAuthTokenFetcher *editTokenFetcher;

@end

@implementation EditSaveViewController

- (NSString *)getSummary {
    return self.summaryText;
}

- (void)setMode:(WMFPreviewAndSaveMode)mode {
    _mode = mode;

    [self updateNavigationForMode:mode];
}

- (void)updateNavigationForMode:(WMFPreviewAndSaveMode)mode {
    UIBarButtonItem *backButton = nil;
    UIBarButtonItem *forwardButton = nil;

    switch (mode) {
        case PREVIEW_MODE_EDIT_WIKITEXT:
            backButton = self.buttonLeftCaret;
            forwardButton = self.buttonNext;
            break;
        case PREVIEW_MODE_EDIT_WIKITEXT_WARNING:
            backButton = self.buttonLeftCaret;
            forwardButton = self.buttonSave;
            break;
        case PREVIEW_MODE_EDIT_WIKITEXT_DISALLOW:
            backButton = self.buttonLeftCaret;
            forwardButton = nil;
            break;
        case PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW:
            backButton = self.buttonLeftCaret;
            forwardButton = self.buttonSave;
            break;
        case PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA:
            backButton = self.buttonX;
            forwardButton = self.buttonSave;
            break;
        default:
            break;
    }

    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationItem.rightBarButtonItem = forwardButton;
}

- (void)goBack {
    if (self.mode == PREVIEW_MODE_EDIT_WIKITEXT_WARNING) {
        [self.funnel logAbuseFilterWarningBack:self.abuseFilterCode];
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)goForward {
    switch (self.mode) {
        case PREVIEW_MODE_EDIT_WIKITEXT_WARNING:
            [self save];
            [self.funnel logAbuseFilterWarningIgnore:self.abuseFilterCode];
            break;
        case PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA:
            [self save];
            break;
        default:
            [self save];
            break;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.theme) {
        self.theme = [WMFTheme standard];
    }

    self.navigationItem.title = WMFLocalizedStringWithDefaultValue(@"wikitext-preview-save-changes-title", nil, nil, @"Save your changes", @"Title for edit preview screens");

    self.previewLicenseView.previewLicenseViewDelegate = self;

    self.buttonX = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(goBack)];

    self.buttonLeftCaret = [UIBarButtonItem wmf_buttonType:WMFButtonTypeCaretLeft target:self action:@selector(goBack)];

    self.buttonSave = [[UIBarButtonItem alloc] initWithTitle:WMFLocalizedStringWithDefaultValue(@"button-publish", nil, nil, @"Publish", @"Button text for publish button used in various places.\n{{Identical|Publish}}") style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];

    self.mode = PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW;

    self.summaryText = @"";

    //self.saveAutomaticallyIfSignedIn = NO;

    [self.funnel logPreview];

    self.borderWidth = 1.0f / [UIScreen mainScreen].scale;

    self.editSummaryViewController.delegate = self;
    
    [self applyTheme:self.theme];
}

- (void)viewWillAppear:(BOOL)animated {
    self.captchaScrollView.alpha = 0.0f;

    self.captchaViewController = [WMFCaptchaViewController wmf_initialViewControllerFromClassStoryboard];
    self.captchaViewController.captchaDelegate = self;
    [self wmf_addWithChildController:self.captchaViewController andConstrainToEdgesOfContainerView:self.captchaContainer];

    self.mode = PREVIEW_MODE_EDIT_WIKITEXT_PREVIEW;


    EditSummaryViewController *vc = [[EditSummaryViewController alloc] initWithNibName:[EditSummaryViewController wmf_classStoryboardName] bundle:nil];
    vc.delegate = self;
    [self wmf_addWithChildController:vc andConstrainToEdgesOfContainerView:self.editSummaryVCContainer];
    vc.theme = self.theme;
    //[self wmf_addChildControllerFromNibFor:[EditSummaryViewController class] andConstrainToEdgesOfContainerView:self.editSummaryVCContainer];


    //[self saveAutomaticallyIfNecessary];


    if ([[WMFAuthenticationManager sharedInstance] isLoggedIn]) {
        self.previewLicenseView.licenseLoginLabel.userInteractionEnabled = NO;
        self.previewLicenseView.licenseLoginLabel.attributedText = nil;
    } else {
        self.previewLicenseView.licenseLoginLabel.userInteractionEnabled = YES;
    }

    self.previewLicenseTapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(licenseLabelTapped:)];
    [self.previewLicenseView.licenseLoginLabel addGestureRecognizer:self.previewLicenseTapGestureRecognizer];

    [super viewWillAppear:animated];
}

- (void)licenseLabelTapped:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // Call if user taps the blue "Log In" text in the CC text.
        //self.saveAutomaticallyIfSignedIn = YES;
        WMFLoginViewController *loginVC = [WMFLoginViewController wmf_initialViewControllerFromClassStoryboard];
        loginVC.funnel = [[WMFLoginFunnel alloc] init];
        [loginVC.funnel logStartFromEdit:self.funnel.editSessionToken];
        [loginVC applyTheme:self.theme];
        UINavigationController *nc = [[WMFThemeableNavigationController alloc] initWithRootViewController:loginVC theme:self.theme];
        [self presentViewController:nc animated:YES completion:nil];
    }
}

- (void)highlightCaptchaSubmitButton:(BOOL)highlight {
    self.buttonSave.enabled = highlight;
}

- (void)viewWillDisappear:(BOOL)animated {
    [[WMFAlertManager sharedInstance] dismissAlert];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"TabularScrollViewItemTapped"
                                                  object:nil];

    [self.previewLicenseView.licenseLoginLabel removeGestureRecognizer:self.previewLicenseTapGestureRecognizer];

    [super viewWillDisappear:animated];
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError *)error {
    if ([sender isKindOfClass:[WikiTextSectionUploader class]]) {

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                [self.funnel logSavedRevision:[fetchedData[@"newrevid"] intValue]];
                dispatchOnMainQueue(^{
                    [self.delegate editSaveViewControllerDidSave:self];
                });
            } break;

            case FETCH_FINAL_STATUS_CANCELLED: {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
            } break;

            case FETCH_FINAL_STATUS_FAILED: {

                switch (error.code) {
                    case WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA: {
                        if (self.mode == PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA) {
                            [self.funnel logCaptchaFailure];
                        }

                        NSURL *captchaUrl = [[NSURL alloc] initWithString:error.userInfo[@"captchaUrl"]];
                        NSString *captchaId = error.userInfo[@"captchaId"];
                        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
                        self.captchaViewController.captcha = [[WMFCaptcha alloc] initWithCaptchaID:captchaId captchaURL:captchaUrl];
                        [self revealCaptcha];
                    } break;

                    case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED:
                    case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING:
                    case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER: {
                        //NSString *warningHtml = error.userInfo[@"warning"];
                        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];

                        [self wmf_hideKeyboard];

                        if ((error.code == WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED)) {
                            self.mode = PREVIEW_MODE_EDIT_WIKITEXT_DISALLOW;
                            self.abuseFilterCode = error.userInfo[@"code"];
                            [self.funnel logAbuseFilterError:self.abuseFilterCode];
                        } else {
                            self.mode = PREVIEW_MODE_EDIT_WIKITEXT_WARNING;
                            self.abuseFilterCode = error.userInfo[@"code"];
                            [self.funnel logAbuseFilterWarning:self.abuseFilterCode];
                        }

                        // Hides the license panel. Needed if logged in and a disallow is triggered.
                        [[WMFAlertManager sharedInstance] dismissAlert];

                        AbuseFilterAlertType alertType =
                            (error.code == WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED) ? ABUSE_FILTER_DISALLOW : ABUSE_FILTER_WARNING;
                        [self showAbuseFilterAlertOfType:alertType];
                    } break;

                    case WIKITEXT_UPLOAD_ERROR_SERVER:
                    case WIKITEXT_UPLOAD_ERROR_UNKNOWN:
                        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];

                        [self.funnel logError:error.localizedDescription]; // @fixme is this right msg?
                        break;

                    default:
                        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
                        break;
                }
            } break;
        }
    }
}

- (void)save {
    //TODO: maybe? if we have credentials, yet the edit token retrieved for an edit
    // is an anonymous token (i think this happens if you try to get an edit token
    // and your login session has expired), need to pop up alert asking user if they
    // want to log in before continuing with their edit

    [[WMFAlertManager sharedInstance] showAlert:WMFLocalizedStringWithDefaultValue(@"wikitext-upload-save", nil, nil, @"Publishing...", @"Alert text shown when changes to section wikitext are being published\n{{Identical|Publishing}}") sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];

    [self.funnel logSaveAttempt];
    if (self.savedPagesFunnel) {
        [self.savedPagesFunnel logEditAttemptWithArticleURL:self.section.article.url];
    }

    [[QueuesSingleton sharedInstance].sectionWikiTextUploadManager wmf_cancelAllTasksWithCompletionHandler:^{
        // If fromTitle was set, the section was transcluded, so use the title of the page
        // it was transcluded from.
        NSURL *editURL = self.section.fromURL ? self.section.fromURL : self.section.article.url;

        // First try to get an edit token for the page's domain before trying to upload the changes.
        // Only the domain is used to actually fetch the token, the other values are
        // parked in EditTokenFetcher so the actual uploader can have quick read-only
        // access to the exact params which kicked off the token request.

        NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:editURL.wmf_language];
        self.editTokenFetcher = [[WMFAuthTokenFetcher alloc] init];
        @weakify(self)
            [self.editTokenFetcher fetchTokenOfType:WMFAuthTokenTypeCsrf
                siteURL:url
                success:^(WMFAuthToken *result) {
                    @strongify(self)

                        self.wikiTextSectionUploader =
                        [[WikiTextSectionUploader alloc] initAndUploadWikiText:self.wikiText
                                                                 forArticleURL:editURL
                                                                       section:[NSString stringWithFormat:@"%d", self.section.sectionId]
                                                                       summary:[self getSummary]
                                                                     captchaId:self.captchaViewController.captcha.captchaID
                                                                   captchaWord:self.captchaViewController.solution
                                                                         token:result.token
                                                                   withManager:[QueuesSingleton sharedInstance].sectionWikiTextUploadManager
                                                            thenNotifyDelegate:self];
                }
                failure:^(NSError *error) {
                    [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
                }];
    }];
}

- (void)showAbuseFilterAlertOfType:(AbuseFilterAlertType)alertType {
    AbuseFilterAlert *abuseFilterAlert = [[AbuseFilterAlert alloc] initWithType:alertType];

    [self.view addSubview:abuseFilterAlert];

    NSDictionary *views = @{@"abuseFilterAlert": abuseFilterAlert};

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[abuseFilterAlert]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[abuseFilterAlert]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.captchaViewController.solution.length > 0) {
        [self save];
    }
    return YES;
}

- (NSURL *_Nonnull)captchaSiteURL {
    return [SessionSingleton sharedInstance].currentArticleSiteURL;
}

- (void)captchaReloadPushed:(id)sender {
}

- (BOOL)captchaHideSubtitle {
    return YES;
}

- (void)captchaKeyboardReturnKeyTapped {
    [self save];
}

- (void)captchaSolutionChanged:(id)sender solutionText:(nullable NSString *)solutionText {
    [self highlightCaptchaSubmitButton:(solutionText.length == 0) ? NO : YES];
}

- (void)revealCaptcha {
    [self.funnel logCaptchaShown];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.35];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:self.view
                             cache:NO];

    [self.view bringSubviewToFront:self.captchaScrollView];

    self.captchaScrollView.alpha = 1.0f;
    self.captchaScrollView.backgroundColor = self.theme.colors.paperBackground;

    self.captchaScrollContainer.backgroundColor = [UIColor clearColor];
    self.captchaContainer.backgroundColor = [UIColor clearColor];

    [UIView commitAnimations];

    self.mode = PREVIEW_MODE_EDIT_WIKITEXT_CAPTCHA;

    [self highlightCaptchaSubmitButton:NO];
}

- (void)previewLicenseViewTermsLicenseLabelWasTapped:(PreviewLicenseView *)previewLicenseview {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLicenses.localizedSaveTermsTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [self wmf_openExternalUrl:WMFLicenses.saveTermsURL];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLicenses.localizedCCBYSA3Title
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [self wmf_openExternalUrl:WMFLicenses.CCBYSA3URL];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLicenses.localizedGFDLTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [self wmf_openExternalUrl:WMFLicenses.GFDLURL];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"open-link-cancel", nil, nil, @"Cancel", @"Text for cancel button in popup menu of terms/license link options\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:sheet animated:YES completion:NULL];
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.scrollView.backgroundColor = theme.colors.paperBackground;
    self.captchaScrollView.backgroundColor = theme.colors.baseBackground;

    [self.previewLicenseView applyTheme:theme];

    self.scrollContainer.backgroundColor = theme.colors.paperBackground;
    self.captchaContainer.backgroundColor = theme.colors.paperBackground;
    self.captchaScrollContainer.backgroundColor = theme.colors.paperBackground;
}

- (void)learnMoreButtonTappedWithSender:(UIButton * _Nonnull)sender {
    [self wmf_openExternalUrl:[NSURL URLWithString:@"https://en.wikipedia.org/wiki/Help:Edit_summary"]];
}

- (void)summaryChangedWithNewSummary:(NSString * _Nullable)newSummary {
    self.summaryText = newSummary;
}

- (void)cannedButtonTappedWithType:(enum EditSummaryViewCannedButtonType)type {
    NSString *eventLoggingKey;
    switch (type) {
        case EditSummaryViewCannedButtonTypeTypo:
            eventLoggingKey = @"typo";
            break;
        case EditSummaryViewCannedButtonTypeGrammar:
            eventLoggingKey = @"grammar";
            break;
        case EditSummaryViewCannedButtonTypeLink:
            eventLoggingKey = @"links";
            break;
        default:
            break;
    }
    [self.funnel logEditSummaryTap:eventLoggingKey];
}

@end
