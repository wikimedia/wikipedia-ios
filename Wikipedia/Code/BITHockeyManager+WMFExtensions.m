
#import "BITHockeyManager+WMFExtensions.h"
#import "WikipediaAppUtils.h"
#import "NSBundle+WMFInfoUtils.h"
#import "WMFCrashAlertView.h"
#import "DDLog+WMFLogger.h"


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
    NSString* appID = [[NSBundle mainBundle] wmf_hockeyappIdentifier];
    DDLogError(@"app ID: %@", appID);

    if ([appID length] == 0) {
        DDLogError(@"Not setting up hockey becuase no app ID was found");
        return;
    }


    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:appID];

#if DEBUG
    [BITHockeyManager sharedHockeyManager].debugLogEnabled = YES;
#endif
    [BITHockeyManager sharedHockeyManager].updateManager.updateSetting = BITUpdateCheckManually;
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    //We always wnat usrs to have the chance to send a crash report.
    if ([[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus == BITCrashManagerStatusDisabled) {
        [[BITHockeyManager sharedHockeyManager] crashManager].crashManagerStatus = BITCrashManagerStatusAlwaysAsk;
    }

    [[BITHockeyManager sharedHockeyManager] crashManager].enableAppNotTerminatingCleanlyDetection = YES;
    [BITHockeyManager sharedHockeyManager].delegate                                               = self;
    [[BITHockeyManager sharedHockeyManager] wmf_setupCrashNotificationAlert];
    [[BITHockeyManager sharedHockeyManager] startManager];
    DDLogInfo(@"Starting crash manager.");
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

- (NSString*)applicationLogForCrashManager:(BITCrashManager*)crashManager {
    return [DDLog wmf_currentLogFile];
}

@end
