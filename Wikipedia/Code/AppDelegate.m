

#import "AppDelegate.h"
#import "Wikipedia-Swift.h"

#import "BITHockeyManager+WMFExtensions.h"
#import "PiwikTracker+WMFExtensions.h"
#import "WMFAppViewController.h"


@import Tweaks;

@interface AppDelegate ()

@property (nonatomic, strong) WMFAppViewController* appViewController;

@end

@implementation AppDelegate

+ (void)load {
    /**
     * Register default application preferences.
     * @note This must be loaded before application launch so unit tests can run
     */
    NSString* defaultLanguage = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
         @"CurrentArticleDomain": defaultLanguage,
         @"Domain": defaultLanguage,
         @"ZeroWarnWhenLeaving": @YES,
         @"ZeroOnDialogShownOnce": @NO,
         @"FakeZeroOn": @NO,
         @"LastHousekeepingDate": [NSDate date],
         @"SendUsageReports": @NO,
         @"AccessSavedPagesMessageShown": @NO
     }];
}

- (UIWindow*)window {
    if (!_window) {
        _window = [[FBTweakShakeWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _window;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    [[NSUserDefaults standardUserDefaults] wmf_setAppLaunchDate:[NSDate date]];
    [[BITHockeyManager sharedHockeyManager] wmf_setupAndStart];
    [PiwikTracker wmf_start];

    WMFAppViewController* vc = [WMFAppViewController initialAppViewControllerFromDefaultStoryBoard];
    [vc launchAppInWindow:self.window];
    self.appViewController = vc;

    NSLog(@"%@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);

    return YES;
}

- (void)applicationWillResignActive:(UIApplication*)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSUserDefaults standardUserDefaults] wmf_setAppResignActiveDate:[NSDate date]];
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    [[NSUserDefaults standardUserDefaults] wmf_setAppBecomeActiveDate:[NSDate date]];
}

- (void)applicationWillTerminate:(UIApplication*)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// TODO: fetch saved pages in the background
//- (void)application:(UIApplication *)application
//    performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
//}

@end
