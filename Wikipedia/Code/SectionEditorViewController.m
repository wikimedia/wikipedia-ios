#import "SectionEditorViewController.h"

#import "WikiTextSectionFetcher.h"
#import "PreviewAndSaveViewController.h"
#import "MWLanguageInfo.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIScrollView+WMFScrollsToTop.h"
#import "Wikipedia-Swift.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
@import BlocksKitUIKitExtensions;

#define EDIT_TEXT_VIEW_FONT [UIFont systemFontOfSize:16.0f]
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MIN (25.0f)
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MAX (25.0f)

@interface SectionEditorViewController () <PreviewAndSaveViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *editTextView;
@property (strong, nonatomic) NSString *unmodifiedWikiText;
@property (nonatomic) CGRect viewKeyboardRect;
@property (strong, nonatomic) UIBarButtonItem *rightButton;

@end

@implementation SectionEditorViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    @weakify(self)
        UIBarButtonItem *buttonX = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX
                                                           handler:^(id sender) {
                                                               @strongify(self)
                                                                   [self.delegate sectionEditorFinishedEditing:self
                                                                                                   withChanges:NO];
                                                           }];
    buttonX.accessibilityLabel = MWLocalizedString(@"back-button-accessibility-label", nil);
    self.navigationItem.leftBarButtonItem = buttonX;

    self.rightButton = [[UIBarButtonItem alloc] bk_initWithTitle:MWLocalizedString(@"button-next", nil)
                                                           style:UIBarButtonItemStylePlain
                                                         handler:^(id sender) {
                                                             @strongify(self)

                                                                 if (![self changesMade]) {
                                                                 [[WMFAlertManager sharedInstance] showAlert:MWLocalizedString(@"wikitext-preview-changes-none", nil) sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
                                                             }
                                                             else {
                                                                 [self preview];
                                                             }
                                                         }];
    self.navigationItem.rightBarButtonItem = self.rightButton;

    self.unmodifiedWikiText = nil;

    [self.editTextView setDelegate:self];

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        // Fix for strange ios 7 bug with large pages of text in the edit text view
        // jumping around if scrolled quickly.
        self.editTextView.layoutManager.allowsNonContiguousLayout = NO;
    }

    [self loadLatestWikiTextForSectionFromServer];

    if ([self.editTextView respondsToSelector:@selector(keyboardDismissMode)]) {
        self.editTextView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }

    self.viewKeyboardRect = CGRectNull;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self highlightProgressiveButton:[self changesMade]];

    [self scrollTextViewSoCursorNotUnderKeyboard:textView];
}

- (BOOL)changesMade {
    if (!self.unmodifiedWikiText) {
        return NO;
    }
    return ![self.unmodifiedWikiText isEqualToString:self.editTextView.text];
}

- (void)highlightProgressiveButton:(BOOL)highlight {
    self.navigationItem.rightBarButtonItem.enabled = highlight;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self registerForKeyboardNotifications];

    [self.editTextView wmf_shouldScrollToTopOnStatusBarTap:YES];

    [self highlightProgressiveButton:[self changesMade]];

    if ([self changesMade]) {
        // Needed to keep keyboard on screen when cancelling out of preview.
        [self.editTextView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self unRegisterForKeyboardNotifications];

    [self highlightProgressiveButton:NO];

    [super viewWillDisappear:animated];
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError *)error {
    if ([sender isKindOfClass:[WikiTextSectionFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                WikiTextSectionFetcher *wikiTextSectionFetcher = (WikiTextSectionFetcher *)sender;
                NSDictionary *resultsDict = (NSDictionary *)fetchedData;
                NSString *revision = resultsDict[@"revision"];
                NSDictionary *userInfo = resultsDict[@"userInfo"];

                self.funnel = [[EditFunnel alloc] initWithUserId:[userInfo[@"id"] intValue]];
                [self.funnel logStart];

                MWKProtectionStatus *protectionStatus = wikiTextSectionFetcher.section.article.protection;

                if (protectionStatus && [[protectionStatus allowedGroupsForAction:@"edit"] count] > 0) {
                    NSArray *groups = [protectionStatus allowedGroupsForAction:@"edit"];
                    NSString *msg;
                    if ([groups indexOfObject:@"autoconfirmed"] != NSNotFound) {
                        msg = MWLocalizedString(@"page_protected_autoconfirmed", nil);
                    } else if ([groups indexOfObject:@"sysop"] != NSNotFound) {
                        msg = MWLocalizedString(@"page_protected_sysop", nil);
                    } else {
                        msg = MWLocalizedString(@"page_protected_other", nil);
                    }
                    [[WMFAlertManager sharedInstance] showAlert:msg sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
                } else {
                    //[self showAlert:MWLocalizedString(@"wikitext-download-success", nil) type:ALERT_TYPE_TOP duration:1];
                    [[WMFAlertManager sharedInstance] dismissAlert];
                }
                self.unmodifiedWikiText = revision;
                self.editTextView.attributedText = [self getAttributedString:revision];
                //[self.editTextView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4f];
            } break;
            case FETCH_FINAL_STATUS_CANCELLED: {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
            } break;
            case FETCH_FINAL_STATUS_FAILED: {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
            } break;
        }
    }
}

- (void)loadLatestWikiTextForSectionFromServer {
    [[WMFAlertManager sharedInstance] showAlert:MWLocalizedString(@"wikitext-downloading", nil) sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];

    [[QueuesSingleton sharedInstance].sectionWikiTextDownloadManager wmf_cancelAllTasksWithCompletionHandler:^{
        (void)[[WikiTextSectionFetcher alloc] initAndFetchWikiTextForSection:self.section
                                                                 withManager:[QueuesSingleton sharedInstance].sectionWikiTextDownloadManager
                                                          thenNotifyDelegate:self];
    }];
}

- (NSAttributedString *)getAttributedString:(NSString *)string {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.maximumLineHeight = EDIT_TEXT_VIEW_LINE_HEIGHT_MIN;
    paragraphStyle.minimumLineHeight = EDIT_TEXT_VIEW_LINE_HEIGHT_MAX;

    paragraphStyle.headIndent = 10.0;
    paragraphStyle.firstLineHeadIndent = 10.0;
    paragraphStyle.tailIndent = -10.0;

    return
        [[NSAttributedString alloc] initWithString:string
                                        attributes:@{
                                            NSParagraphStyleAttributeName: paragraphStyle,
                                            NSFontAttributeName: EDIT_TEXT_VIEW_FONT,
                                        }];
}

- (void)preview {
    PreviewAndSaveViewController *previewVC = [PreviewAndSaveViewController wmf_initialViewControllerFromClassStoryboard];
    previewVC.section = self.section;
    previewVC.wikiText = self.editTextView.text;
    previewVC.funnel = self.funnel;
    previewVC.savedPagesFunnel = self.savedPagesFunnel;
    previewVC.delegate = self;
    [self.navigationController pushViewController:previewVC animated:YES];
}

- (void)previewViewControllerDidSave:(PreviewAndSaveViewController *)previewViewController {
    [self.delegate sectionEditorFinishedEditing:self withChanges:YES];
}

#pragma mark Keyboard

// Ensure the edit text view can scroll whatever text it is displaying all the
// way so the bottom of the text can be scrolled to the top of the screen.
// More info here:
// https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)unRegisterForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    NSDictionary *info = [aNotification userInfo];

    CGRect windowKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGRect viewKeyboardRect = [self.view.window convertRect:windowKeyboardRect toView:self.view];

    self.viewKeyboardRect = viewKeyboardRect;

    // This makes it so you can always scroll to the bottom of the text view's text
    // even if the keyboard is onscreen.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, viewKeyboardRect.size.height, 0.0);
    self.editTextView.contentInset = contentInsets;
    self.editTextView.scrollIndicatorInsets = contentInsets;

    // Mark the text view as needing a layout update so the inset changes above will
    // be taken in to account when the cursor is scrolled onscreen.
    [self.editTextView setNeedsLayout];
    [self.editTextView layoutIfNeeded];

    // Scroll cursor onscreen if needed.
    [self scrollTextViewSoCursorNotUnderKeyboard:self.editTextView];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.editTextView.contentInset = contentInsets;
    self.editTextView.scrollIndicatorInsets = contentInsets;

    self.viewKeyboardRect = CGRectNull;
}

- (void)scrollTextViewSoCursorNotUnderKeyboard:(UITextView *)textView {
    // If cursor is hidden by keyboard, scroll the text view so cursor is onscreen.
    if (!CGRectIsNull(self.viewKeyboardRect)) {
        CGRect cursorRectInTextView = [textView caretRectForPosition:textView.selectedTextRange.start];
        CGRect cursorRectInView = [textView convertRect:cursorRectInTextView toView:self.view];
        if (CGRectIntersectsRect(self.viewKeyboardRect, cursorRectInView)) {
            CGFloat margin = -20;
            // Margin here is the amount the cursor will be scrolled above the top of the keyboard.
            cursorRectInTextView = CGRectInset(cursorRectInTextView, 0, margin);

            [textView scrollRectToVisible:cursorRectInTextView animated:YES];
        }
    }
}

#pragma mark Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape {
    [self.navigationController popViewControllerAnimated:YES];
    return YES;
}

@end
