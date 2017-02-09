#import "BITHockeyManager+WMFExtensions.h"
#import "NSBundle+WMFInfoUtils.h"
#import "DDLog+WMFLogger.h"

// See also:
// http://support.hockeyapp.net/kb/client-integration-ios-mac-os-x/hockeyapp-for-ios
// http://hockeyapp.net/help/sdk/ios/3.6.2/docs/docs/HowTo-Set-Custom-AlertViewHandler.html

static NSString *const kHockeyAppTitleStringsKey = @"hockeyapp-alert-title";
static NSString *const kHockeyAppQuestionStringsKey = @"hockeyapp-alert-question";
static NSString *const kHockeyAppQuestionWithResponseFieldStringsKey = @"hockeyapp-alert-question-with-response-field";
static NSString *const kHockeyAppSendStringsKey = @"hockeyapp-alert-send-report";
static NSString *const kHockeyAppAlwaysSendStringsKey = @"hockeyapp-alert-always-send";
static NSString *const kHockeyAppDoNotSendStringsKey = @"hockeyapp-alert-do-not-send";

@implementation BITHockeyManager (WMFExtensions)

+ (NSString *)crashSendText {
    return MWLocalizedString(kHockeyAppSendStringsKey, nil);
}

+ (NSString *)crashAlwaysSendText {
    return MWLocalizedString(kHockeyAppAlwaysSendStringsKey, nil);
}

+ (NSString *)crashDoNotSendText {
    return MWLocalizedString(kHockeyAppDoNotSendStringsKey, nil);
}

- (void)wmf_setupAndStart {
    NSString *appID = [[NSBundle mainBundle] wmf_hockeyappIdentifier];
    DDLogError(@"app ID: %@", appID);

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
NSString *const kHockeyAppPrivacyStringsKey = @"hockeyapp-alert-privacy";
NSString *const kHockeyAppPrivacyUrl = @"http://hockeyapp.net/privacy/";

- (void)wmf_setupCrashNotificationAlert {
    [[BITHockeyManager sharedHockeyManager].crashManager setAlertViewHandler:^() {
        NSString *title = [MWLocalizedString(kHockeyAppTitleStringsKey, nil)
            stringByReplacingOccurrencesOfString:@"$1"
                                      withString:WMFHockeyAppServiceName];
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
        [customAlertView addAction:[UIAlertAction actionWithTitle:[MWLocalizedString(kHockeyAppPrivacyStringsKey, nil)
                                                                      stringByReplacingOccurrencesOfString:@"$1"
                                                                                                withString:WMFHockeyAppServiceName]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kHockeyAppPrivacyUrl]];

                                                          }]];

        NSString *exceptionReason = [[BITHockeyManager sharedHockeyManager].crashManager lastSessionCrashDetails].exceptionReason;
        if (exceptionReason) {
            customAlertView.message = [MWLocalizedString(kHockeyAppQuestionWithResponseFieldStringsKey, nil) stringByReplacingOccurrencesOfString:@"$1" withString:WMFHockeyAppServiceName];
            [customAlertView addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField){

            }];
        } else {
            customAlertView.message = [MWLocalizedString(kHockeyAppQuestionStringsKey, nil) stringByReplacingOccurrencesOfString:@"$1" withString:WMFHockeyAppServiceName];
        }
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:customAlertView animated:YES completion:NULL];
    }];
}

- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager {
    return [DDLog wmf_currentLogFile];
}

@end
