//
//  AppDelegate.m
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import "AppDelegate.h"
#import "URLCache.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set the shared url cache to our custom NSURLCache which re-routes images to
    // our article cache.
//TODO: update the app to occasionally check total size of our article cache and if its file exceeded some threshold size prune its image entries
// (probably by Image.lastDateAccessed)
    URLCache *urlCache = [[URLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                 diskCapacity:20 * 1024 * 1024
                                                     diskPath:nil];
    [NSURLCache setSharedURLCache:urlCache];

    [self registerStandardUserDefaults];
    [self systemWideStyleOverrides];

    // Enables Alignment Rect highlighting for debugging
    //[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UIViewShowAlignmentRects"];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    // Override point for customization after application launch.
    return YES;
}

-(void)registerStandardUserDefaults
{
    // Register default default values.
    // See: http://stackoverflow.com/a/5397647/135557
    NSDictionary *userDefaultsDefaults = @{@"CurrentArticleTitle": @""};
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsDefaults];
}

-(void)systemWideStyleOverrides
{
    // Minimize flicker of search result table cells being recycled as they
    // pass completely beneath translucent nav bars
    [[UIApplication sharedApplication] delegate].window.backgroundColor = [UIColor whiteColor];
    
    CGRect rect = CGRectMake(0, 0, 10, 10);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [[UIColor clearColor] setFill];
    UIRectFill(rect);
    UIImage *clearImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        // Pre iOS 7:
        // Change the appearance of the nav bar throughout the app
        // (do not do this for iOS 7 or above)
        [[UINavigationBar appearance] setTintColor:[UIColor clearColor]];
        [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.3f]];
        [[UINavigationBar appearance] setBackgroundImage:clearImage forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setShadowImage:clearImage];
        
    }else{
        // Post iOS 7:
        // Set the color of the nav bar and other system icons
        [[UIApplication sharedApplication] delegate].window.tintColor = [UIColor whiteColor];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        
        // Set the blinky-cursor color for text boxes
        [[UITextField appearance] setTintColor:[UIColor colorWithWhite:0.0f alpha:0.35f]];
        [[UITextView appearance] setTintColor:[UIColor colorWithWhite:0.0f alpha:0.35f]];
    }
    
    [[UIButton appearance] setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
