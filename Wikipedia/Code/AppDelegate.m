

#import "AppDelegate.h"
#import "Wikipedia-Swift.h"

#import "BITHockeyManager+WMFExtensions.h"
#import "PiwikTracker+WMFExtensions.h"
#import "WMFAppViewController.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"
#import "WMFDailyStatsLoggingFunnel.h"
#import <Tweaks/FBTweakShakeWindow.h>
#import "ZeroConfigState.h"

#import <GCDWebServers/GCDWebServer.h>
#import <GCDWebServers/GCDWebServerDataResponse.h>
#import <GCDWebServers/GCDWebServerErrorResponse.h>

@interface AppDelegate ()

@property (nonatomic, strong) WMFAppViewController* appViewController;
@property (nonatomic, strong) WMFDailyStatsLoggingFunnel* statsFunnel;

@property (nonatomic, strong) GCDWebServer* webServer;

@end

@implementation AppDelegate

#pragma mark - Defaults

+ (void)load {
    /**
     * Register default application preferences.
     * @note This must be loaded before application launch so unit tests can run
     */
    NSString* defaultLanguage = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
         @"CurrentArticleDomain": defaultLanguage,
         @"Domain": defaultLanguage,
         ZeroWarnWhenLeaving: @YES,
         ZeroOnDialogShownOnce: @NO,
         @"LastHousekeepingDate": [NSDate date],
         @"SendUsageReports": @NO,
         @"AccessSavedPagesMessageShown": @NO
     }];
}

#pragma mark - Accessors

- (UIWindow*)window {
    if (!_window) {
        if ([[[NSProcessInfo processInfo] environment][@"FBTweakShakeWindowEnabled"] boolValue]) {
            _window = [[FBTweakShakeWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        } else {
            _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        }
    }
    return _window;
}

- (WMFDailyStatsLoggingFunnel*)statsFunnel {
    if (!_statsFunnel) {
        _statsFunnel = [[WMFDailyStatsLoggingFunnel alloc] init];
    }
    return _statsFunnel;
}

#pragma mark - Shortcuts

- (void)updateDynamicIconShortcutItems {
    if (![[UIApplication sharedApplication] respondsToSelector:@selector(shortcutItems)]) {
        return;
    }

    NSMutableArray<UIApplicationShortcutItem*>* shortcutItems =
        [[NSMutableArray alloc] initWithObjects:
         [UIApplicationShortcutItem wmf_random],
         [UIApplicationShortcutItem wmf_nearby],
         nil
        ];

    [shortcutItems wmf_safeAddObject:[UIApplicationShortcutItem wmf_continueReading]];

    [shortcutItems addObject:[UIApplicationShortcutItem wmf_search]];

    [UIApplication sharedApplication].shortcutItems = shortcutItems;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    [[BITHockeyManager sharedHockeyManager] wmf_setupAndStart];
    [PiwikTracker wmf_start];

    [[NSUserDefaults standardUserDefaults] wmf_setAppLaunchDate:[NSDate date]];
    [[NSUserDefaults standardUserDefaults] wmf_setAppInstallDateIfNil:[NSDate date]];

    [self.statsFunnel logAppNumberOfDaysSinceInstall];

    WMFAppViewController* vc = [WMFAppViewController initialAppViewControllerFromDefaultStoryBoard];
    [vc launchAppInWindow:self.window];
    self.appViewController = vc;

    [self updateDynamicIconShortcutItems];

    NSLog(@"%@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);

    self.webServer = [[GCDWebServer alloc] init];

    @weakify(self);
    [self.webServer addHandlerForMethod:@"GET" path:@"/imageProxy" requestClass:[GCDWebServerRequest class]
                      asyncProcessBlock:^(GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock) {
        @strongify(self);

        GCDWebServerErrorResponse* notFound = [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"Image not found"];

        NSString* originalSrc = request.query[@"originalSrc"];
        if (originalSrc) {
            if (!([originalSrc hasPrefix:@"http"] || [originalSrc hasPrefix:@"https"])) {
                originalSrc = [@"http:" stringByAppendingString:originalSrc];
            }

            NSURL* imgURL = [NSURL URLWithString:originalSrc];

            NSAssert(imgURL, @"imageProxy URL should not be nil");

            NSURLCache* URLCache = [NSURLCache sharedURLCache];
            NSURLRequest* request = [NSURLRequest requestWithURL:imgURL];
            NSCachedURLResponse* cachedResponse = [URLCache cachedResponseForRequest:request];


            if (cachedResponse.response && cachedResponse.data) {
                NSString* mimeType = cachedResponse.response.MIMEType;
                if (!mimeType) {
                    mimeType = [imgURL wmf_mimeTypeForExtension];
                }
                GCDWebServerDataResponse* gcdResponse = [[GCDWebServerDataResponse alloc] initWithData:cachedResponse.data contentType:mimeType];
                completionBlock(gcdResponse);
            } else {
                NSURLSessionDataTask* downloadImgTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData* imgData, NSURLResponse* response, NSError* error) {
                    GCDWebServerDataResponse* gcdResponse = [[GCDWebServerDataResponse alloc] initWithData:imgData contentType:response.MIMEType];
                    completionBlock(gcdResponse);
                    NSCachedURLResponse* responseToCache = [[NSCachedURLResponse alloc] initWithResponse:response data:imgData];
                    [URLCache storeCachedResponse:responseToCache forRequest:request];
                }];
                [downloadImgTask resume];
            }
        } else {
            completionBlock(notFound);
        }
    }];

    [self.webServer startWithPort:8080 bonjourName:nil];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self.statsFunnel logAppNumberOfDaysSinceInstall];
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSUserDefaults standardUserDefaults] wmf_setAppBecomeActiveDate:[NSDate date]];
}

- (void)application:(UIApplication*)application performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [self.appViewController processShortcutItem:shortcutItem completion:completionHandler];
}

- (BOOL)application:(UIApplication*)application continueUserActivity:(NSUserActivity*)userActivity restorationHandler:(void (^)(NSArray* restorableObjects))restorationHandler {
    return [self.appViewController processUserActivity:userActivity];
}

- (void)applicationWillResignActive:(UIApplication*)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSUserDefaults standardUserDefaults] wmf_setAppResignActiveDate:[NSDate date]];
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self updateDynamicIconShortcutItems];
}

- (void)applicationWillTerminate:(UIApplication*)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self applicationDidEnterBackground:application];
}

@end
