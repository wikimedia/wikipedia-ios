#import "AppDelegate.h"
#import "BITHockeyManager+WMFExtensions.h"
#import "PiwikTracker+WMFExtensions.h"
#import "WMFAppViewController.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"
#import <Tweaks/FBTweakShakeWindow.h>
#import "NSUserActivity+WMFExtensions.h"

@interface AppDelegate ()

@property (nonatomic, strong) WMFAppViewController *appViewController;

@end

@implementation AppDelegate

#pragma mark - Defaults

+ (void)load {
    /**
     * Register default application preferences.
     * @note This must be loaded before application launch so unit tests can run
     */
    NSString *defaultLanguage = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    [[NSUserDefaults wmf_userDefaults] registerDefaults:@{
        @"CurrentArticleDomain": defaultLanguage,
        @"Domain": defaultLanguage,
        WMFZeroWarnWhenLeaving: @YES,
        WMFZeroOnDialogShownOnce: @NO,
        @"LastHousekeepingDate": [NSDate date],
        @"SendUsageReports": @NO,
        @"AccessSavedPagesMessageShown": @NO
    }];
}

#pragma mark - Accessors

- (UIWindow *)window {
    if (!_window) {
        if ([[[NSProcessInfo processInfo] environment][@"FBTweakShakeWindowEnabled"] boolValue]) {
            _window = [[FBTweakShakeWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        } else {
            _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        }
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

    [shortcutItems wmf_safeAddObject:[UIApplicationShortcutItem wmf_continueReading]];

    [shortcutItems addObject:[UIApplicationShortcutItem wmf_search]];

    [UIApplication sharedApplication].shortcutItems = shortcutItems;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if DEBUG
    NSLog(@"\n\nSimulator documents directory:\n\t%@\n\n",
          [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);
#endif

    [NSUserDefaults wmf_migrateToWMFGroupUserDefaultsIfNecessary];
    [[BITHockeyManager sharedHockeyManager] wmf_setupAndStart];
    [PiwikTracker wmf_start];

    [[NSUserDefaults wmf_userDefaults] wmf_setAppLaunchDate:[NSDate date]];
    [[NSUserDefaults wmf_userDefaults] wmf_setAppInstallDateIfNil:[NSDate date]];

    WMFAppViewController *vc = [WMFAppViewController initialAppViewControllerFromDefaultStoryBoard];
    [vc launchAppInWindow:self.window];
    self.appViewController = vc;

    [self updateDynamicIconShortcutItems];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSUserDefaults wmf_userDefaults] wmf_setAppBecomeActiveDate:[NSDate date]];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [self.appViewController processShortcutItem:shortcutItem completion:completionHandler];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    return [self.appViewController processUserActivity:userActivity];
}

- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {
    return [self application:application openURL:url options:@{}];
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    if (activity) {
        return [self.appViewController processUserActivity:activity];
    } else {
        return NO;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSUserDefaults wmf_userDefaults] wmf_setAppResignActiveDate:[NSDate date]];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self updateDynamicIconShortcutItems];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self applicationDidEnterBackground:application];
}

@end
