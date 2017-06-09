@import HockeySDK;

@interface BITHockeyManager (WMFExtensions) <BITHockeyManagerDelegate>

/**
 *  Configure and startup in one line.
 *  This will call the methods below as part of the configuration process.
 *  This method will use the current bundle id of the app
 */
- (void)wmf_setupAndStart;

/**
 *  Configure the alert to be displayed when a user is prompeted to send a crash report
 */
- (void)wmf_setupCrashNotificationAlert;

@end
