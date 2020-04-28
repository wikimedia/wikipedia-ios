@import UIKit;
@import UserNotifications;
@class WMFTheme;
@class MWKDataStore;
@class WMFTheme;

NS_ASSUME_NONNULL_BEGIN

@interface WMFAppViewController : UITabBarController <UNUserNotificationCenterDelegate>

@property (nonatomic, readonly, nullable) UINavigationController *currentNavigationController;
@property (nonatomic, readonly) WMFTheme *theme;
@property (nonatomic, readonly) MWKDataStore *dataStore;

- (void)launchAppInWindow:(UIWindow *)window waitToResumeApp:(BOOL)waitToResumeApp;

- (void)showSplashView;

- (void)hideSplashViewAnimated:(BOOL)animated;

- (void)hideSplashScreenAndResumeApp; // Updates explore feed & other heavy network lifitng

- (void)processShortcutItem:(UIApplicationShortcutItem *)item completion:(void (^)(BOOL))completion;

- (BOOL)processUserActivity:(NSUserActivity *)activity animated:(BOOL)animated completion:(dispatch_block_t)done;

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

- (void)applyTheme:(WMFTheme *)theme;

- (void)showSearchInCurrentNavigationController;

/// Returning WMFArticleViewController (which is ArticleViewController in Swift) makes this not work from Swift
- (void)swiftCompatibleShowArticleWithURL:(NSURL *)articleURL animated:(BOOL)animated completion:(nonnull dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
