#import "WMFUserNotificationsController.h"
#import <UserNotifications/UserNotifications.h>

@interface WMFUserNotificationsController ()
@property (nonatomic, retain) NSTimer *timer;
@end

@implementation WMFUserNotificationsController

- (void)start {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            
        }];
    });
}

- (void)stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timer invalidate];
        self.timer = nil;
    });
}

@end
