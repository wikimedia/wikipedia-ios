@import UIKit;
@import UserNotifications;
@class WMFTheme;
@class MWKDataStore;
@class WMFTheme;
@class ReadingList;
@class WMFComponentNavigationController;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFLanguageVariantAlertsLibraryVersion; // NSNumber

@interface WMFAppViewController : UITabBarController <UNUserNotificationCenterDelegate>

@property (nonatomic, readonly, nullable) UINavigationController *currentNavigationController;
@property (nonatomic, readonly) WMFTheme *theme;
@property (nonatomic, readonly) MWKDataStore *dataStore;

- (void)launchAppInWindow:(UIWindow *)window waitToResumeApp:(BOOL)waitToResumeApp;

- (void)showSplashView;

- (void)hideSplashView;

- (void)hideSplashScreenAndResumeApp; // Updates explore feed & other heavy network lifitng

- (void)processShortcutItem:(UIApplicationShortcutItem *)item completion:(void (^)(BOOL))completion;

- (BOOL)processUserActivity:(NSUserActivity *)activity animated:(BOOL)animated completion:(dispatch_block_t)done;

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

- (void)applyTheme:(WMFTheme *)theme;

- (void)showSearchInCurrentNavigationController;

- (void)showImportedReadingList:(ReadingList *)readingList;

NS_ASSUME_NONNULL_END

- (void)performDatabaseHousekeepingWithCompletion:(void (^_Nonnull)(NSError *_Nullable))completion;

- (void)setRemoteNotificationRegistrationStatusWithDeviceToken:(NSData *_Nullable)deviceToken error:(NSError *_Nullable)error;

NS_ASSUME_NONNULL_BEGIN

@end

// Methods exposed in header for use in WMFAppViewController+Extensions.swift
@interface WMFAppViewController (SwiftInterfaces)
- (void)dismissPresentedViewControllers;
- (void)showSettingsAnimated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END
