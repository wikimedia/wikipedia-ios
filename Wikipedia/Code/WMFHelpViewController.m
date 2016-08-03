
#import "WMFHelpViewController.h"
#import "MWKDataStore.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "WikipediaAppUtils.h"
#import "Wikipedia-Swift.h"
#import "WMFLeadingImageTrailingTextButton.h"
#import "DDLog+WMFLogger.h"

@import MessageUI;

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFSettingsURLFAQ       = @"https://m.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ";
static NSString* const WMFSettingsEmailAddress = @"mobile-ios-wikipedia@wikimedia.org";
static NSString* const WMFSettingsEmailSubject = @"Bug:";

@interface WMFHelpViewController ()<MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UIBarButtonItem* sendEmailToolbarItem;

@end

@implementation WMFHelpViewController


- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSURL* faqURL = [NSURL URLWithString:WMFSettingsURLFAQ];
    self = [super initWithArticleURL:faqURL dataStore:dataStore];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = nil;
}

- (UIBarButtonItem*)sendEmailToolbarItem {
    if (!_sendEmailToolbarItem) {
        WMFLeadingImageTrailingTextButton* button = [[WMFLeadingImageTrailingTextButton alloc] init];
        button.tintColor = [UIColor wmf_blueTintColor];
        [button configureAsReportBugButton];
        [button sizeToFit];
        [button addTarget:self action:@selector(sendEmail) forControlEvents:UIControlEventTouchUpInside];
        _sendEmailToolbarItem                    = [[UIBarButtonItem alloc] initWithCustomView:button];
        _sendEmailToolbarItem.accessibilityLabel = MWLocalizedString(@"table-of-contents-button-label", nil);
        return _sendEmailToolbarItem;
    }
    return _sendEmailToolbarItem;
}

- (NSArray<UIBarButtonItem*>*)articleToolBarItems {
    return [NSArray arrayWithObjects:
            self.sendEmailToolbarItem,
            [UIBarButtonItem flexibleSpaceToolbarItem],
            self.tableOfContentsToolbarItem,
            nil];
}

- (void)sendEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* vc = [[MFMailComposeViewController alloc] init];
        [vc setSubject:[WMFSettingsEmailSubject stringByAppendingString:[WikipediaAppUtils versionedUserAgent]]];
        [vc setToRecipients:@[WMFSettingsEmailAddress]];
        [vc setMessageBody:[NSString stringWithFormat:@"\n\n\n\nVersion: %@", [WikipediaAppUtils versionedUserAgent]] isHTML:NO];
        NSData* data = [[DDLog wmf_currentLogFile] dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            [vc addAttachmentData:data mimeType:@"text/plain" fileName:@"Log Data.txt"];
        }
        vc.mailComposeDelegate = self;
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        [[WMFAlertManager sharedInstance] showErrorAlertWithMessage:MWLocalizedString(@"no-email-account-alert", nil) sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError*)error {
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

@end

NS_ASSUME_NONNULL_END