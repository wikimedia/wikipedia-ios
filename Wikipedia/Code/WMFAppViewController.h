@import UIKit;
@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface WMFAppViewController : UITabBarController <UNUserNotificationCenterDelegate>

- (void)launchAppInWindow:(UIWindow *)window waitToResumeApp:(BOOL)waitToResumeApp;

- (void)hideSplashScreenAndResumeApp; // Updates explore feed & other heavy network lifitng

- (void)processShortcutItem:(UIApplicationShortcutItem *)item completion:(void (^)(BOOL))completion;

- (BOOL)processUserActivity:(NSUserActivity *)activity animated:(BOOL)animated completion:(dispatch_block_t)done;

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

@end

NS_ASSUME_NONNULL_END
