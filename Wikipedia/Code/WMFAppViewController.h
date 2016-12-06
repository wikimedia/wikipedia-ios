@import UserNotifications;

@interface WMFAppViewController : UIViewController <UNUserNotificationCenterDelegate>

+ (instancetype)initialAppViewControllerFromDefaultStoryBoard;

- (void)launchAppInWindow:(UIWindow *)window;

- (void)processShortcutItem:(UIApplicationShortcutItem *)item completion:(void (^)(BOOL))completion;

- (BOOL)processUserActivity:(NSUserActivity *)activity;

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

@end
