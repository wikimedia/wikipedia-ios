//
//  WMFWelcomeAnalyticsViewController.m
//  Wikipedia
//
//  Created by Corey Floyd on 11/24/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFWelcomeAnalyticsViewController.h"
@import HockeySDK;

@interface WMFWelcomeAnalyticsViewController ()
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* toggleLabel;
@property (strong, nonatomic) IBOutlet UIButton* nextStepButton;

@end

@implementation WMFWelcomeAnalyticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
}

- (IBAction)toggleAnalytics:(id)sender {
    if ([(UISwitch*)sender isOn]) {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAutoSend;
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"SendUsageReports"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
        [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"SendUsageReports"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
