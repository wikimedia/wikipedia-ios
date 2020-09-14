#import "AppDelegate.h"
@import UserNotifications;
@import BackgroundTasks;
@import WMF.NSUserActivity_WMFExtensions;
@import WMF.NSFileManager_WMFGroup;
#import "WMFAppViewController.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"
#import "Wikipedia-Swift.h"
#import "WMFQuoteMacros.h"

static NSTimeInterval const WMFBackgroundFetchInterval = 10800; // 3 Hours
static NSString *const WMFBackgroundAppRefreshTaskIdentifier = @"org.wikimedia.wikipedia.appRefresh";

@interface AppDelegate ()

@property (nonatomic, strong) WMFAppViewController *appViewController;
@property (nonatomic) BOOL appNeedsResume;

@end

@implementation AppDelegate

#pragma mark - Defaults

+ (void)load {
    /**
     * Register default application preferences.
     * @note This must be loaded before application launch so unit tests can run
     */
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"WMFAutoSignTalkPageDiscussions": @YES
    }];
}

#pragma mark - Accessors

- (UIWindow *)window {
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _window;
}

#pragma mark - Shortcuts

- (void)updateDynamicIconShortcutItems {
    if (![[UIApplication sharedApplication] respondsToSelector:@selector(shortcutItems)]) {
        return;
    }

    NSMutableArray<UIApplicationShortcutItem *> *shortcutItems =
        [[NSMutableArray alloc] initWithObjects:
                                    [UIApplicationShortcutItem wmf_random],
                                    [UIApplicationShortcutItem wmf_nearby],
                                    nil];

    [shortcutItems addObject:[UIApplicationShortcutItem wmf_search]];

    [UIApplication sharedApplication].shortcutItems = shortcutItems;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerBackgroundTasksForApplication:application];

#if DEBUG
    // Use NSLog so we can break and copy/paste. DDLogDebug is async.
    NSLog(@"\nSimulator container directory:\n\t%@\n",
          [[NSFileManager defaultManager] wmf_containerPath]);
#endif

#if UI_TEST
    if ([[NSUserDefaults standardUserDefaults] wmf_isFastlaneSnapshotInProgress]) {
        [UIView setAnimationsEnabled:NO];
    }
#endif

    [[NSUserDefaults standardUserDefaults] wmf_migrateFontSizeMultiplier];
    NSUserDefaults.standardUserDefaults.shouldRestoreNavigationStackOnResume = [self shouldRestoreNavigationStackOnResumeAfterBecomingActive:[NSDate date]];

    self.appNeedsResume = YES;
    WMFAppViewController *vc = [[WMFAppViewController alloc] init];
    [UNUserNotificationCenter currentNotificationCenter].delegate = vc; // this needs to be set before the end of didFinishLaunchingWithOptions:
    [vc launchAppInWindow:self.window waitToResumeApp:self.appNeedsResume];
    self.appViewController = vc;

    [self updateDynamicIconShortcutItems];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self cancelPendingBackgroundTasks];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self resumeAppIfNecessary];
    [[WMFEventPlatformClient sharedInstance] appInForeground];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [self.appViewController processShortcutItem:shortcutItem completion:completionHandler];
}

#pragma mark - AppVC Resume

- (void)resumeAppIfNecessary {
    if (self.appNeedsResume) {
        [self.appViewController hideSplashScreenAndResumeApp];
        self.appNeedsResume = false;
    }
}

- (BOOL)shouldRestoreNavigationStackOnResumeAfterBecomingActive:(NSDate *)becomeActiveDate {
    BOOL shouldOpenAppOnSearchTab = [NSUserDefaults standardUserDefaults].wmf_openAppOnSearchTab;
    if (shouldOpenAppOnSearchTab) {
        return NO;
    }

    NSDate *resignActiveDate = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }
    NSDate *cutoffDate = [[NSCalendar wmf_utcGregorianCalendar] nextDateAfterDate:resignActiveDate matchingHour:5 minute:0 second:0 options:NSCalendarMatchStrictly];
    BOOL isBeforeCutoffDate = [becomeActiveDate compare:cutoffDate] == NSOrderedAscending;
    return isBeforeCutoffDate;
}

#pragma mark - NSUserActivity Handling

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType {
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *__nullable restorableObjects))restorationHandler {
    [self.appViewController showSplashView];

    BOOL result = [self.appViewController processUserActivity:userActivity
                                                     animated:NO
                                                   completion:^{
                                                       if (self.appNeedsResume) {
                                                           [self resumeAppIfNecessary];
                                                       } else {
                                                           [self.appViewController hideSplashViewAnimated:YES];
                                                       }
                                                   }];
    return result;
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error {
    DDLogDebug(@"didFailToContinueUserActivityWithType: %@ error: %@", userActivityType, error);
}

- (void)application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity {
    DDLogDebug(@"didUpdateUserActivity: %@", userActivity);
}

#pragma mark - NSURL Handling

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url] ?: [NSUserActivity wmf_activityForURL:url];
    if (activity) {
        [self.appViewController showSplashView];
        BOOL result = [self.appViewController processUserActivity:activity
                                                         animated:NO
                                                       completion:^{
                                                           if (self.appNeedsResume) {
                                                               [self resumeAppIfNecessary];
                                                           } else {
                                                               [self.appViewController hideSplashViewAnimated:YES];
                                                           }
                                                       }];
        return result;
    } else {
        [self resumeAppIfNecessary];
        return NO;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSUserDefaults standardUserDefaults] wmf_setAppResignActiveDate:[NSDate date]];
    [[WMFEventPlatformClient sharedInstance] appInBackground];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self updateDynamicIconShortcutItems];
    [self scheduleBackgroundAppRefreshTask];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self applicationDidEnterBackground:application];
    [[WMFEventPlatformClient sharedInstance] appWillClose];
}

#pragma mark - Background Fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.appViewController performBackgroundFetchWithCompletion:completionHandler];
}

/// Cancels any pending background tasks, if applicable on the current platform
- (void)cancelPendingBackgroundTasks {
    if (@available(iOS 13.0, *)) {
        [[BGTaskScheduler sharedScheduler] cancelAllTaskRequests];
    }
}

/// Register for any necessary background tasks or updates with the method appropriate for the platform
- (void)registerBackgroundTasksForApplication:(UIApplication *)application {
    if (@available(iOS 13.0, *)) {
        [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:WMFBackgroundAppRefreshTaskIdentifier
                                                              usingQueue:dispatch_get_main_queue()
                                                           launchHandler:^(__kindof BGTask *_Nonnull task) {
                                                               [self.appViewController performBackgroundFetchWithCompletion:^(UIBackgroundFetchResult result) {
                                                                   switch (result) {
                                                                       case UIBackgroundFetchResultFailed:
                                                                           [task setTaskCompletedWithSuccess:NO];
                                                                           break;
                                                                       default:
                                                                           [task setTaskCompletedWithSuccess:YES];
                                                                           break;
                                                                   }
                                                                   // The next task needs to be scheduled
                                                                   [self scheduleBackgroundAppRefreshTask];
                                                               }];
                                                           }];
    } else {
        [application setMinimumBackgroundFetchInterval:WMFBackgroundFetchInterval];
    }
}

/// Schedule the next background refresh, if applicable on the current platform
- (void)scheduleBackgroundAppRefreshTask {
    if (@available(iOS 13.0, *)) {
        BGAppRefreshTaskRequest *appRefreshTask = [[BGAppRefreshTaskRequest alloc] initWithIdentifier:WMFBackgroundAppRefreshTaskIdentifier];
        appRefreshTask.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:WMFBackgroundFetchInterval];
        NSError *taskSubmitError = nil;
        if (![[BGTaskScheduler sharedScheduler] submitTaskRequest:appRefreshTask error:&taskSubmitError]) {
            DDLogError(@"Unable to schedule background task: %@", taskSubmitError);
        }
    }
}

@end
