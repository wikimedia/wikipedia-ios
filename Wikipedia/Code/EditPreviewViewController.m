#import "EditPreviewViewController.h"
#import "PreviewHtmlFetcher.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "EditFunnel.h"
#import "Wikipedia-Swift.h"

@interface EditPreviewViewController () <FetchFinishedDelegate, UITextFieldDelegate, UIScrollViewDelegate, WMFOpenExternalLinkDelegate, WMFPreviewSectionLanguageInfoDelegate, WMFPreviewAnchorTapAlertDelegate>

@property (strong, nonatomic) IBOutlet PreviewWebViewContainer *previewWebViewContainer;
@property (strong, nonatomic) PreviewHtmlFetcher *previewHtmlFetcher;

@end

@implementation EditPreviewViewController

- (void)wmf_showAlertForTappedAnchorHref:(NSString *)href {
    NSString *title = WMFLocalizedStringWithDefaultValue(@"wikitext-preview-link-preview-title", nil, nil, @"Link preview", @"Title for link preview popup");
    NSString *message = [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"wikitext-preview-link-preview-description", nil, nil, @"This link leads to '%1$@'", @"Description of the link URL. %1$@ is the URL."), href];

    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    // TODO: move "button-ok" to common strings
    [alertController addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"button-ok", nil, nil, @"OK", @"Button text for ok button used in various places\n{{Identical|OK}}")
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    [self presentViewController:alertController
                       animated:YES
                     completion:^{
                     }];
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)goForward {
    [self.delegate editPreviewViewControllerDidTapNext:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.theme) {
        self.theme = [WMFTheme standard];
    }

    self.navigationItem.title = WMFLocalizedStringWithDefaultValue(@"navbar-title-mode-edit-wikitext-preview", nil, nil, @"Preview", @"Header text shown when wikitext changes are being previewed.\n{{Identical|Preview}}");;
    
    self.previewWebViewContainer.externalLinksOpenerDelegate = self;

    self.navigationItem.leftBarButtonItem = [UIBarButtonItem wmf_buttonType:WMFButtonTypeCaretLeft target:self action:@selector(goBack)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WMFCommonStrings.nextTitle style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];

    [self.funnel logPreview];

    [self preview];
    [self applyTheme:self.theme];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[WMFAlertManager sharedInstance] dismissAlert];
    [super viewWillDisappear:animated];
}

- (MWLanguageInfo *)wmf_editedSectionLanguageInfo {
    return [MWLanguageInfo languageInfoForCode:self.section.url.wmf_language];
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError *)error {
    if ([sender isKindOfClass:[PreviewHtmlFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                [[WMFAlertManager sharedInstance] dismissAlert];
                [self.previewWebViewContainer.webView loadHTML:fetchedData baseURL:[NSURL URLWithString:@"https://wikipedia.org"] withAssetsFile:@"preview.html" scrolledToFragment:nil padding:UIEdgeInsetsZero theme:self.theme];
            } break;
            case FETCH_FINAL_STATUS_FAILED: {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
            } break;
            case FETCH_FINAL_STATUS_CANCELLED: {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
            } break;
        }
    }
}

- (void)preview {
    [[WMFAlertManager sharedInstance] showAlert:WMFLocalizedStringWithDefaultValue(@"wikitext-preview-changes", nil, nil, @"Retrieving preview of your changes...", @"Alert text shown when getting preview of user changes to wikitext") sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];

    [[QueuesSingleton sharedInstance].sectionPreviewHtmlFetchManager wmf_cancelAllTasksWithCompletionHandler:^{
        self.previewHtmlFetcher =
            [[PreviewHtmlFetcher alloc] initAndFetchHtmlForWikiText:self.wikiText
                                                         articleURL:self.section.url
                                                        withManager:[QueuesSingleton sharedInstance].sectionPreviewHtmlFetchManager
                                                 thenNotifyDelegate:self];
    }];
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.previewWebViewContainer.webView.opaque = NO;
    self.previewWebViewContainer.webView.scrollView.backgroundColor = [UIColor clearColor];
    self.previewWebViewContainer.webView.backgroundColor = theme.colors.paperBackground;
    self.previewWebViewContainer.backgroundColor = theme.colors.paperBackground;
}

@end
