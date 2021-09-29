@import Foundation;
@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFInTheNewsNotificationCategoryIdentifier;
extern NSString *const WMFInTheNewsNotificationReadNowActionIdentifier;
extern NSString *const WMFInTheNewsNotificationSaveForLaterActionIdentifier;
extern NSString *const WMFInTheNewsNotificationShareActionIdentifier;

extern NSString *const WMFNotificationInfoArticleTitleKey;
extern NSString *const WMFNotificationInfoArticleURLStringKey;
extern NSString *const WMFNotificationInfoThumbnailURLStringKey;
extern NSString *const WMFNotificationInfoArticleExtractKey;
extern NSString *const WMFNotificationInfoViewCountsKey;
extern NSString *const WMFNotificationInfoFeedNewsStoryKey;

@class MWKDataStore, MWKLanguageLinkController;
@protocol WMFNotificationsControllerDeviceTokenDelegate;

@interface WMFNotificationsController : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore languageLinkController:(MWKLanguageLinkController *)languageLinkController NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy, nullable) NSData *remoteRegistrationDeviceToken;
@property (nonatomic, readonly, strong, nullable) NSError *remoteRegistrationError;
@property (nonatomic, weak) id<WMFNotificationsControllerDeviceTokenDelegate> deviceTokenDelegate;
- (BOOL)isWaitingOnDeviceToken;

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

- (void)sendNotificationWithTitle:(NSString *)title body:(NSString *)body categoryIdentifier:(NSString *)categoryIdentifier userInfo:(NSDictionary *)userInfo atDateComponents:(nullable NSDateComponents *)dateComponents; //null date components will send the notification ASAP

/// Registers notification categories for the app. Should only be called once at launch.
- (void)updateCategories;

- (void)setRemoteNotificationRegistrationStatusWithDeviceToken:(nullable NSData *)deviceToken error:(nullable NSError *)error;

@end

@protocol WMFNotificationsControllerDeviceTokenDelegate
- (void)didUpdateDeviceTokenStatusFromNotificationsController: (WMFNotificationsController *)controller;
@end

NS_ASSUME_NONNULL_END
