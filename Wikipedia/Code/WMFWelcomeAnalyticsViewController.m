#import "WMFWelcomeAnalyticsViewController.h"
#import "Wikipedia-Swift.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIButton+WMFWelcomeNextButton.h"

@import HockeySDK;

@interface WMFWelcomeAnalyticsViewController ()
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *toggleLabel;
@property (strong, nonatomic) IBOutlet UIButton *nextStepButton;
@property (strong, nonatomic) IBOutlet UISwitch *toggle;
@property (strong, nonatomic) IBOutlet WelcomeAnalyticsAnimationView *animationView;

@end

@implementation WMFWelcomeAnalyticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text = [MWLocalizedString(@"welcome-volunteer-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.subTitleLabel.text = MWLocalizedString(@"welcome-volunteer-sub-title", nil);

    [self.nextStepButton wmf_configureAsWelcomeNextButton];

    [self updateToggleLabelTitleForUsageReportsIsOn:NO];

    //Set state of the toggle. Also make sure crash manager setting is in sync with this setting - likely to happen on first launch or for previous users.
    if ([[NSUserDefaults wmf_userDefaults] wmf_sendUsageReports]) {
        self.toggle.on = YES;
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAutoSend;
    } else {
        self.toggle.on = NO;
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
    }

    self.animationView.backgroundColor = [UIColor clearColor];
}

- (void)viewDidAppear:(BOOL)animated {
    BOOL shouldAnimate = !self.hasAlreadyFaded;
    [super viewDidAppear:animated];
    if (shouldAnimate) {
        [self.animationView beginAnimations];
    }
}

- (IBAction)toggleAnalytics:(UISwitch *)sender {
    if ([sender isOn]) {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAutoSend;
        [[NSUserDefaults wmf_userDefaults] wmf_setSendUsageReports:YES];
    } else {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
        [[NSUserDefaults wmf_userDefaults] wmf_setSendUsageReports:NO];
    }
    [self updateToggleLabelTitleForUsageReportsIsOn:[sender isOn]];
}

- (IBAction)showPrivacyPolicy:(id)sender {
    [self wmf_openExternalUrl:[NSURL URLWithString:URL_PRIVACY_POLICY]];
}

- (void)updateToggleLabelTitleForUsageReportsIsOn:(BOOL)isOn {
    NSString *title = isOn ? [MWLocalizedString(@"welcome-volunteer-thanks", nil) stringByReplacingOccurrencesOfString:@"$1" withString:@"😀"] : MWLocalizedString(@"welcome-volunteer-send-usage-reports", nil);
    self.toggleLabel.text = title;
}

@end
