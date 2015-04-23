
#import <HockeySDK/HockeySDK.h>

@interface BITHockeyManager (WMFExtensions)

/**
 *  Configure and startup in one line.
 *  This will call the methods below as part of the configuration process.
 *  This method will use the current bundle id of the app
 */
- (void)wmf_setupAndStart;

/**
 *  Set the Hockey API Key based on a bundle ID
 *
 *  @param bundleID The bundle ID to map to an API Key
 *
 *  @return YES if successful, otherwise NO
 */
- (BOOL)wmf_setAPIKeyForBundleID:(NSString*)bundleID;

/**
 *  Configure the alert to be displayed when a user is prompeted to send a crash report
 */
- (void)wmf_setupCrashNotificationAlert;

@end
