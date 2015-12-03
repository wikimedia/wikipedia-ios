
#import "WMFWelcomeAnalyticsViewController.h"
#import "Wikipedia-Swift.h"
#import "UIViewController+WMFOpenExternalUrl.h"

@import HockeySDK;

@interface WMFWelcomeAnalyticsViewController ()
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* detailLabel;
@property (strong, nonatomic) IBOutlet UILabel* toggleLabel;
@property (strong, nonatomic) IBOutlet UIButton* nextStepButton;
@property (strong, nonatomic) IBOutlet UIButton* privacyPolicyButton;
@property (strong, nonatomic) IBOutlet UISwitch* toggle;

@end

@implementation WMFWelcomeAnalyticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text  = MWLocalizedString(@"welcome-usage-reports-title", nil);
    self.detailLabel.text = MWLocalizedString(@"welcome-usage-reports-body-text", nil);
    self.toggleLabel.text = MWLocalizedString(@"welcome-usage-reports-switch-text", nil);
    [self.nextStepButton setTitle:MWLocalizedString(@"welcome-usage-reports-button-title", nil) forState:UIControlStateNormal];
    [self.privacyPolicyButton setTitle:MWLocalizedString(@"welcome-usage-reports-privacy-policy-button-text", nil) forState:UIControlStateNormal];

    //Set state of the toggle. Also make sure crash manager setting is in sync with this setting - likely to happen on first launch or for previous users.
    if ([[NSUserDefaults standardUserDefaults] wmf_sendUsageReports]) {
        self.toggle.on                                                           = YES;
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAutoSend;
    } else {
        self.toggle.on                                                           = NO;
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
    }
}

- (IBAction)toggleAnalytics:(id)sender {
    if ([(UISwitch*)sender isOn]) {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAutoSend;
        [[NSUserDefaults standardUserDefaults] wmf_setSendUsageReports:YES];
    } else {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
        [[NSUserDefaults standardUserDefaults] wmf_setSendUsageReports:NO];
    }
}

- (IBAction)showPrivacyPolicy:(id)sender {
    [self wmf_openExternalUrl:[NSURL URLWithString:URL_PRIVACY_POLICY]];
}

@end
