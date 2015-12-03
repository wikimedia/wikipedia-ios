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

@end
