@import UIKit;
@import UserNotifications;
@class WMFTheme;

NS_ASSUME_NONNULL_BEGIN

@interface WMFAppViewController : UITabBarController <UNUserNotificationCenterDelegate>

- (void)launchAppInWindow:(UIWindow *)window waitToResumeApp:(BOOL)waitToResumeApp;

- (void)showSplashViewIfNotShowing;

- (void)hideSplashViewAnimated:(BOOL)animated;

- (void)hideSplashScreenAndResumeApp; // Updates explore feed & other heavy network lifitng

- (void)processShortcutItem:(UIApplicationShortcutItem *)item completion:(void (^)(BOOL))completion;

- (BOOL)processUserActivity:(NSUserActivity *)activity animated:(BOOL)animated completion:(dispatch_block_t)done;

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

- (void)applyTheme:(WMFTheme *)theme;

- (void)showSearchInCurrentNavigationController;

@end

NS_ASSUME_NONNULL_END
