
#import <HockeySDK/HockeySDK.h>

@interface BITHockeyManager (WMFExtensions)

/**
 *  Configure and startup in on line.
 *  This will call the methods below as part of the configuration process.
 *  This method will use the current bundle id of the app
 */
- (void)setupAndStart;

/**
 *  Set the Hockey API Key based on a bundle ID
 *
 *  @param bundleID The bundle ID to map to an API Key
 */
- (void)setAPIKeyForBundleID:(NSString*)bundleID;

/**
 *  Configure the alert to be displayed when a user is prompeted to send a crash report
 */
- (void)setupCrashNotificationAlert;

@end
