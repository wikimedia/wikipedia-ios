
#import "BITHockeyManager+WMFExtensions.h"
#import "WikipediaAppUtils.h"
#import "WMFCrashAlertView.h"

// See also:
// http://support.hockeyapp.net/kb/client-integration-ios-mac-os-x/hockeyapp-for-ios
// http://hockeyapp.net/help/sdk/ios/3.6.2/docs/docs/HowTo-Set-Custom-AlertViewHandler.html

static NSString* const kHockeyAppTitleStringsKey                     = @"hockeyapp-alert-title";
static NSString* const kHockeyAppQuestionStringsKey                  = @"hockeyapp-alert-question";
static NSString* const kHockeyAppQuestionWithResponseFieldStringsKey = @"hockeyapp-alert-question-with-response-field";
static NSString* const kHockeyAppSendStringsKey                      = @"hockeyapp-alert-send-report";
static NSString* const kHockeyAppAlwaysSendStringsKey                = @"hockeyapp-alert-always-send";
static NSString* const kHockeyAppDoNotSendStringsKey                 = @"hockeyapp-alert-do-not-send";

@implementation BITHockeyManager (WMFExtensions)

+ (NSString*)crashReportingIDFor:(NSString*)bundleID {
    static NSDictionary* hockeyAPIKeysByBundleID;
    if (!hockeyAPIKeysByBundleID) {
        hockeyAPIKeysByBundleID = @{
            @"org.wikimedia.wikipedia.tfbeta": @"2295c3698bbd0b050f257772dd2bdbb2",
            @"org.wikimedia.wikipedia.tfalpha": @"38c83eea9df95b47d210c8ad137e815a",
            @"org.wikimedia.wikipedia": @"5d80da08a6761e5c6456736af7ebad88",
            @"org.wikimedia.wikipedia.developer": @"76947f174e31a9e33fe67d81ff31732e"
        };
    }

    return hockeyAPIKeysByBundleID[bundleID];
}

+ (NSString*)crashSendText {
    return MWLocalizedString(kHockeyAppSendStringsKey, nil);
}

+ (NSString*)crashAlwaysSendText {
    return MWLocalizedString(kHockeyAppAlwaysSendStringsKey, nil);
}

+ (NSString*)crashDoNotSendText {
    return MWLocalizedString(kHockeyAppDoNotSendStringsKey, nil);
}

- (void)wmf_setupAndStart {
    NSString* bundleID = [WikipediaAppUtils bundleID];

    if ([[BITHockeyManager sharedHockeyManager] wmf_setAPIKeyForBundleID:bundleID]) {
        [[BITHockeyManager sharedHockeyManager] startManager];

        [BITHockeyManager sharedHockeyManager].updateManager.updateSetting = BITUpdateCheckManually;

        [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

        [[BITHockeyManager sharedHockeyManager] wmf_setupCrashNotificationAlert];
    }
}

- (BOOL)wmf_setAPIKeyForBundleID:(NSString*)bundleID {
    NSString* crashReportingAppID = [[self class] crashReportingIDFor:bundleID];
    if (!crashReportingAppID) {
        return NO;
    }
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:crashReportingAppID];

    return YES;
}

- (void)wmf_setupCrashNotificationAlert {
    [[BITHockeyManager sharedHockeyManager].crashManager setAlertViewHandler:^(){
        NSString* title = [MWLocalizedString(kHockeyAppTitleStringsKey, nil)
                           stringByReplacingOccurrencesOfString:@"$1" withString:WMFHockeyAppServiceName];
        WMFCrashAlertView* customAlertView = [[WMFCrashAlertView alloc] initWithTitle:title
                                                                              message:nil
                                                                             delegate:self
                                                                    cancelButtonTitle:nil
                                                                    otherButtonTitles:
                                              [[self class] crashSendText],
                                              [[self class] crashAlwaysSendText],
                                              [[self class] crashDoNotSendText],
                                              [WMFCrashAlertView wmf_hockeyAppPrivacyButtonText],
                                              nil];
        NSString* exceptionReason = [[BITHockeyManager sharedHockeyManager].crashManager lastSessionCrashDetails].exceptionReason;
        if (exceptionReason) {
            customAlertView.message = [MWLocalizedString(kHockeyAppQuestionWithResponseFieldStringsKey, nil) stringByReplacingOccurrencesOfString:@"$1" withString:WMFHockeyAppServiceName];
            customAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        } else {
            customAlertView.message = [MWLocalizedString(kHockeyAppQuestionStringsKey, nil) stringByReplacingOccurrencesOfString:@"$1" withString:WMFHockeyAppServiceName];
        }
        [customAlertView show];
    }];
}

- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    BITCrashMetaData* crashMetaData = [BITCrashMetaData new];
    if (alertView.alertViewStyle != UIAlertViewStyleDefault) {
        crashMetaData.userDescription = [alertView textFieldAtIndex:0].text;
    }
    NSString* buttonText = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonText isEqualToString:[[self class] crashSendText]]) {
        [[BITHockeyManager sharedHockeyManager].crashManager handleUserInput:BITCrashManagerUserInputSend withUserProvidedMetaData:crashMetaData];
    } else if ([buttonText isEqualToString:[[self class] crashAlwaysSendText]]) {
        [[BITHockeyManager sharedHockeyManager].crashManager handleUserInput:BITCrashManagerUserInputAlwaysSend withUserProvidedMetaData:crashMetaData];
    } else if ([buttonText isEqualToString:[[self class] crashDoNotSendText]]) {
        [[BITHockeyManager sharedHockeyManager].crashManager handleUserInput:BITCrashManagerUserInputDontSend withUserProvidedMetaData:nil];
    }
}

@end
