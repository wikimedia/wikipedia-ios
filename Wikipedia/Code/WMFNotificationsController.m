#import "WMFNotificationsController.h"
@import UserNotifications;
@import WMFUtilities;
@import WMFModel;

NSString *const WMFInTheNewsNotificationCategoryIdentifier = @"inTheNewsNotificationCategoryIdentifier";
NSString *const WMFInTheNewsNotificationReadNowActionIdentifier = @"inTheNewsNotificationReadNowActionIdentifier";

uint64_t const WMFNotificationUpdateInterval = 10;

NSString *const WMFNotificationInfoArticleTitleKey = @"articleTitle";
NSString *const WMFNotificationInfoArticleURLStringKey = @"articleURLString";
NSString *const WMFNotificationInfoThumbnailURLStringKey = @"thumbnailURLString";
NSString *const WMFNotificationInfoArticleExtractKey = @"articleExtract";
NSString *const WMFNotificationInfoStoryHTMLKey = @"storyHTML";
NSString *const WMFNotificationInfoViewCountsKey = @"viewCounts";

@interface WMFNotificationsController ()
@property (nonatomic, strong) dispatch_queue_t notificationQueue;
@property (nonatomic, strong) dispatch_source_t notificationSource;
@end

@implementation WMFNotificationsController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.notificationQueue = dispatch_queue_create("org.wikimedia.notifications", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)start {
    [self requestAuthenticationIfNecessaryWithCompletionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error) {
            DDLogError(@"Error requesting authentication: %@", error);
        }
        dispatch_async(self.notificationQueue, ^{
            self.notificationSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0 , self.notificationQueue);
            dispatch_source_set_timer(self.notificationSource, DISPATCH_TIME_NOW, WMFNotificationUpdateInterval*NSEC_PER_SEC, WMFNotificationUpdateInterval*NSEC_PER_SEC/10);
            dispatch_source_set_event_handler(self.notificationSource, ^{
                [self sendNotification];
            });
            dispatch_resume(self.notificationSource);
        });
    }];
}

- (void)requestAuthenticationIfNecessaryWithCompletionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNNotificationAction *readNowAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationReadNowActionIdentifier title:NSLocalizedString(@"in-the-news-read-now-action", @"in-the-news-read-now-action") options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *inTheNewsCategory = [UNNotificationCategory categoryWithIdentifier:WMFInTheNewsNotificationCategoryIdentifier actions:@[readNowAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    [center setNotificationCategories:[NSSet setWithObject:inTheNewsCategory]];
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound completionHandler:completionHandler];
}

- (void)sendNotification {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    NSString *HTMLString = @"<!--Sep 25--> The <b id=\"mwCw\"><a rel=\"mw:WikiLink\" href=\"./Five_hundred_meter_Aperture_Spherical_Telescope\" title=\"Five hundred meter Aperture Spherical Telescope\" id=\"mwDA\">Five hundred meter Aperture Spherical Telescope</a></b> (FAST) makes its <a rel=\"mw:WikiLink\" href=\"./First_light_(astronomy)\" title=\"First light (astronomy)\" id=\"mwDQ\">first observations</a> in <a rel=\"mw:WikiLink\" href=\"./Guizhou\" title=\"Guizhou\" id=\"mwDg\">Guizhou</a>, China.";
    content.title = NSLocalizedString(@"in-the-news-notification-title", nil);
    content.body = [HTMLString wmf_stringByRemovingHTML];
    content.categoryIdentifier = WMFInTheNewsNotificationCategoryIdentifier;

    content.userInfo = @{
                         WMFNotificationInfoArticleTitleKey: @"Five hundred meter Aperture Spherical Telescope",
                         WMFNotificationInfoArticleURLStringKey: @"https://en.wikipedia.org/wiki/Five_hundred_meter_Aperture_Spherical_Telescope",
                         WMFNotificationInfoThumbnailURLStringKey: @"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/FastTelescope%2A8sep2015.jpg/320px-FastTelescope%2A8sep2015.jpg",
                         WMFNotificationInfoArticleExtractKey: @"The Five hundred metre Aperture Spherical Telescope (FAST; Chinese: 五百米口径球面射电望远镜), nicknamed Tianyan (天眼, lit. \"Heavenly Eye\" or \"The Eye of Heaven\"), is a radio telescope located in the Dawodang depression (大窝凼洼地), a natural basin in Pingtang County, Guizhou Province, southwest China.",
                         WMFNotificationInfoStoryHTMLKey: HTMLString,
                         WMFNotificationInfoViewCountsKey: @[@1, @1, @2, @2, @1, @2, @10]
                         };
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5 repeats:NO];
    NSString *identifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            DDLogError(@"Error adding notification request: %@", error);
        }
    }];
}

- (void)stop {
    dispatch_async(self.notificationQueue, ^{
        if (self.notificationSource) {
            dispatch_source_cancel(self.notificationSource);
            self.notificationSource = NULL;
        }
    });
}

@end
