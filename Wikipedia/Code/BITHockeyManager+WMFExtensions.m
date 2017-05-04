#import "BITHockeyManager+WMFExtensions.h"
#import "NSBundle+WMFInfoUtils.h"
#import "DDLog+WMFLogger.h"

// See also:
// http://support.hockeyapp.net/kb/client-integration-ios-mac-os-x/hockeyapp-for-ios
// http://hockeyapp.net/help/sdk/ios/3.6.2/docs/docs/HowTo-Set-Custom-AlertViewHandler.html

@implementation BITHockeyManager (WMFExtensions)

+ (NSString *)crashSendText {
    return WMFLocalizedStringWithDefaultValue(@"hockeyapp-alert-send-report", nil, nil, @"Send report", @"Alert dialog button text for crash reporting to be sent");
}

+ (NSString *)crashAlwaysSendText {
    return WMFLocalizedStringWithDefaultValue(@"hockeyapp-alert-always-send", nil, nil, @"Always send", @"Alert dialog button text for crash reporting to always be sent");
}

+ (NSString *)crashDoNotSendText {
    return WMFLocalizedStringWithDefaultValue(@"hockeyapp-alert-do-not-send", nil, nil, @"Do not send", @"Alert dialog button text for crash reporting to not send the crash report");
}

- (void)wmf_setupAndStart {
    NSString *appID = [[NSBundle mainBundle] wmf_hockeyappIdentifier];
    if ([appID length] == 0) {
        DDLogError(@"Not setting up hockey because no app ID was found");
        return;
    }

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:appID];

#if DEBUG
    [BITHockeyManager sharedHockeyManager].logLevel = BITLogLevelDebug;
#else
    [BITHockeyManager sharedHockeyManager].logLevel = BITLogLevelError;
#endif
    [BITHockeyManager sharedHockeyManager].updateManager.updateSetting = BITUpdateCheckManually;
    [BITHockeyManager sharedHockeyManager].metricsManager.disabled = NO;
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    //We always wnat usrs to have the chance to send a crash report.
    if ([[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus == BITCrashManagerStatusDisabled) {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
    }

    [[BITHockeyManager sharedHockeyManager] crashManager].enableAppNotTerminatingCleanlyDetection = YES;
    [BITHockeyManager sharedHockeyManager].delegate = self;
    [[BITHockeyManager sharedHockeyManager] wmf_setupCrashNotificationAlert];
    [[BITHockeyManager sharedHockeyManager] startManager];
    DDLogInfo(@"Starting crash manager.");
}

NSString *const WMFHockeyAppServiceName = @"HockeyApp";
NSString *const kHockeyAppPrivacyUrl = @"http://hockeyapp.net/privacy/";

- (void)wmf_setupCrashNotificationAlert {
    [[BITHockeyManager sharedHockeyManager].crashManager setAlertViewHandler:^() {
        NSString *title = [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"hockeyapp-alert-title", nil, nil, @"Sorry, app crashed last time", @"Concise and conciliatory alert dialog title for crash reporting"), WMFHockeyAppServiceName];
        UIAlertController *customAlertView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
        [customAlertView addAction:[UIAlertAction actionWithTitle:[[self class] crashSendText]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                              BITCrashMetaData *crashMetaData = [BITCrashMetaData new];
                                                              crashMetaData.userProvidedDescription = [[[customAlertView textFields] firstObject] text];
                                                              [[BITHockeyManager sharedHockeyManager].crashManager handleUserInput:BITCrashManagerUserInputSend withUserProvidedMetaData:crashMetaData];
                                                          }]];
        [customAlertView addAction:[UIAlertAction actionWithTitle:[[self class] crashAlwaysSendText]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                              BITCrashMetaData *crashMetaData = [BITCrashMetaData new];
                                                              crashMetaData.userProvidedDescription = [[[customAlertView textFields] firstObject] text];
                                                              [[BITHockeyManager sharedHockeyManager].crashManager handleUserInput:BITCrashManagerUserInputAlwaysSend withUserProvidedMetaData:crashMetaData];
                                                          }]];
        [customAlertView addAction:[UIAlertAction actionWithTitle:[[self class] crashDoNotSendText]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                              BITCrashMetaData *crashMetaData = [BITCrashMetaData new];
                                                              crashMetaData.userProvidedDescription = [[[customAlertView textFields] firstObject] text];
                                                              [[BITHockeyManager sharedHockeyManager].crashManager handleUserInput:BITCrashManagerUserInputDontSend withUserProvidedMetaData:nil];
                                                          }]];
        [customAlertView addAction:[UIAlertAction actionWithTitle:[NSString localizedStringWithFormat: WMFLocalizedStringWithDefaultValue(@"hockeyapp-alert-privacy", nil, nil, @"%1$@ privacy", @"Alert dialog button text for HockeyApp privacy policy. %1$@ will be replaced programmatically with the constant string 'HockeyApp'"), WMFHockeyAppServiceName]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kHockeyAppPrivacyUrl]];

                                                          }]];

        NSString *exceptionReason = [[BITHockeyManager sharedHockeyManager].crashManager lastSessionCrashDetails].exceptionReason;
        if (exceptionReason) {
            customAlertView.message = [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"hockeyapp-alert-question-with-response-field", nil, nil, @"Would you like to send a crash report to %1$@ so the Wikimedia Foundation can review your crash? Please describe what happened when the crash occurred:", @"Alert dialog question asking user whether to send a crash report to HockeyApp crash reporting server, and asking the user to describe what happened when the crash occurred. %1$@ will be replaced programmatically with the constant string 'HockeyApp'"), WMFHockeyAppServiceName];
            [customAlertView addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField){

            }];
        } else {
            customAlertView.message = [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"hockeyapp-alert-question", nil, nil, @"Would you like to send a crash report to %1$@ so the Wikimedia Foundation can review your crash?", @"Alert dialog question asking user whether to send a crash report to HockeyApp crash reporting server. %1$@ will be replaced programmatically with the constant string 'HockeyApp'"), WMFHockeyAppServiceName];
        }
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:customAlertView animated:YES completion:NULL];
    }];
}

- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager {
    return [DDLog wmf_currentLogFile];
}

@end
