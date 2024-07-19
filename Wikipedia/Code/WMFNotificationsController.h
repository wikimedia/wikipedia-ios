#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@class MWKDataStore, MWKLanguageLinkController;

@interface WMFNotificationsController : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore languageLinkController:(MWKLanguageLinkController *)languageLinkController NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy, nullable) NSData *remoteRegistrationDeviceToken;
@property (nonatomic, readonly, strong, nullable) NSError *remoteRegistrationError;

/// Checks and returns UNNotificationCenter's authorization status asynchronously. If state is .notDetermined, asks permissions from user and returns result.
/// @param completionHandler Completion handler to call when authorization state has been requested (if needed) and determined. isAllowed = true if it's any state besides UNAuthorizationStatusDenied.
- (void)requestPermissionsIfNecessaryWithCompletionHandler:(void (^)(BOOL isAllowed, NSError *__nullable error))completionHandler;

/// Checks and returns UNNotificationCenter's authorization status asynchronously.
/// @param completionHandler Completion handler to call when authorization state has been determined. Passes back UNAuthorizationStatus from UNUserNotificationCenter
- (void)notificationPermissionsStatusWithCompletionHandler:(void (^)(UNAuthorizationStatus status))completionHandler;

/// Posts device token to server, so server can begin sending push notifications to APNS
/// @param completionHandler Called when subscription completes with success flag and error with more details
- (void)subscribeToEchoNotificationsWithCompletionHandler:(nullable void (^)(NSError *__nullable error))completionHandler;

/// Asks server to remove device token, so server can stop sending push notifications to APNS
/// @param completionHandler Called when unsubscribe call completes with success flag and error with more details
- (void)unsubscribeFromEchoNotificationsWithCompletionHandler:(nullable void (^)(NSError *__nullable error))completionHandler;

- (void)setRemoteNotificationRegistrationStatusWithDeviceToken:(nullable NSData *)deviceToken error:(nullable NSError *)error;

- (void)authenticationManagerWillLogOut:(void (^)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
