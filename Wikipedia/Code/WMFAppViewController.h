@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface WMFAppViewController : UIViewController <UNUserNotificationCenterDelegate>

+ (instancetype)initialAppViewControllerFromDefaultStoryBoard;

- (void)launchAppInWindow:(UIWindow *)window waitToResumeApp:(BOOL)waitToResumeApp;

- (void)resumeApp; // Updates explore feed & other heavy network lifitng 

- (void)processShortcutItem:(UIApplicationShortcutItem *)item completion:(void (^)(BOOL))completion;

- (BOOL)processUserActivity:(NSUserActivity *)activity completion:(dispatch_block_t)done;

- (void)performBackgroundFetchWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

@end

NS_ASSUME_NONNULL_END
