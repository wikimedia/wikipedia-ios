#import "WMFUserNotificationsController.h"
#import <UserNotifications/UserNotifications.h>

static NSString *const WMFInTheNewsNotificationCategoryIdentifier = @"inTheNewsNotificationCategoryIdentifier";
static NSString *const WMFInTheNewsNotificationReadNowActionIdentifier = @"inTheNewsNotificationReadNowActionIdentifier";

static uint64_t const WMFNotificationUpdateInterval = 10;

@interface WMFUserNotificationsController ()
@property (nonatomic, strong) dispatch_queue_t notificationQueue;
@property (nonatomic, strong) dispatch_source_t notificationSource;
@end

@implementation WMFUserNotificationsController

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
    content.title = @"title";
    content.subtitle = @"subtitle";
    content.body = @"body";
    content.categoryIdentifier = WMFInTheNewsNotificationCategoryIdentifier;
    content.userInfo = @{@"user":@"info"};
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
