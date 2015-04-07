//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AppDelegate.h"
#import "NSDate-Utilities.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "BITHockeyManager+WMFExtensions.h"
#import "AppDelegate+DataMigrationProgressDelegate.h"
#import "UIWindow+WMFMainScreenWindow.h"


@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize window = _window;

- (UIWindow*)window {
    if (!_window) {
        _window = [UIWindow wmf_newWithMainScreenBounds];
    }
    return _window;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    [[BITHockeyManager sharedHockeyManager] setupAndStart];

    [self systemWideStyleOverrides];

    // Enables Alignment Rect highlighting for debugging
    //[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UIViewShowAlignmentRects"];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    // Override point for customization after application launch.

    //[self printAllNotificationsToConsole];

#if TARGET_IPHONE_SIMULATOR
    // From: http://pinkstone.co.uk/where-is-the-documents-directory-for-the-ios-8-simulator/
    NSLog(@"\n\n\nSimulator Documents Directory:\n%@\n\n\n",
          [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                  inDomains:NSUserDomainMask] lastObject]);
#endif

    if (![self presentDataMigrationViewControllerIfNeeded]) {
        [self presentRootViewController:NO withSplash:YES];
    }

    return YES;
}

- (void)transitionToRootViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if (!animated || !self.window.rootViewController) {
        self.window.rootViewController = viewController;
        [self.window makeKeyAndVisible];
    } else {
        NSParameterAssert(self.window.isKeyWindow);
        [UIView transitionWithView:self.window
                          duration:[CATransaction animationDuration]
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ self.window.rootViewController = viewController; }
                        completion:nil];
    }
}

- (void)presentRootViewController:(BOOL)animated withSplash:(BOOL)withSplash {
    RootViewController* mainInitialVC =
        [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateInitialViewController];
    NSParameterAssert([mainInitialVC isKindOfClass:[RootViewController class]]);
    mainInitialVC.shouldShowSplashOnAppear = withSplash;
    [self transitionToRootViewController:mainInitialVC animated:animated];
}

- (void)printAllNotificationsToConsole {
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:nil
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification* notification) {
        NSLog(@"NOTIFICATION %@ -> %@", notification.name, notification.userInfo);
    }];
}

- (void)systemWideStyleOverrides {
    // Minimize flicker of search result table cells being recycled as they
    // pass completely beneath translucent nav bars
    [[UIApplication sharedApplication] delegate].window.backgroundColor = [UIColor whiteColor];

/*
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        // Pre iOS 7:
        CGRect rect = CGRectMake(0, 0, 10, 10);
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
        [[UIColor clearColor] setFill];
        UIRectFill(rect);
        UIImage *bgImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        [[UINavigationBar appearance] setTintColor:[UIColor clearColor]];
        [[UINavigationBar appearance] setBackgroundImage:bgImage forBarMetrics:UIBarMetricsDefault];
    }
 */

    [[UIButton appearance] setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];

    // Make buttons look the same on iOS 6 & 7.
    [[UIButton appearance] setBackgroundImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal];
    [[UIButton appearance] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
}

- (void)applicationWillResignActive:(UIApplication*)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
}

- (void)applicationWillTerminate:(UIApplication*)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
