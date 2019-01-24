#import <WMF/WMFTaskGroup.h>
#import <WMF/WMFLogging.h>
#import <WMF/WMFGCDHelpers.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>

@interface WMFTaskGroup ()

@property (nonatomic) dispatch_group_t group;
@property (nonatomic) NSInteger count;

@end

@implementation WMFTaskGroup

- (instancetype)init {
    self = [super init];
    if (self) {
        self.group = dispatch_group_create();
    }
    return self;
}
- (void)enter {
    @synchronized(self) {
        self.count++;
        dispatch_group_enter(_group);
    }
}

- (void)leave {
    @synchronized(self) {
        if (self.count > 0) {
            self.count--;
            dispatch_group_leave(self.group);
        } else {
            DDLogError(@"Mismatched leave for group: %@", self);
        }
    }
}

- (void)waitInBackgroundAndNotifyOnQueue:(nonnull dispatch_queue_t)queue withBlock:(nonnull dispatch_block_t)block {
    if (!block) {
        return;
    }
    dispatch_group_notify(self.group, queue, block);
}

- (void)waitInBackgroundWithCompletion:(nonnull dispatch_block_t)completion {
    [self waitInBackgroundAndNotifyOnQueue:dispatch_get_main_queue() withBlock:completion];
}

- (void)waitInBackgroundWithTimeout:(NSTimeInterval)timeout completion:(nonnull dispatch_block_t)completion {
    if (!completion) {
        return;
    }
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_group_wait(self.group, time);
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    });
}

- (void)waitWithTimeout:(NSTimeInterval)timeout {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC);
    dispatch_group_wait(self.group, time);
}

- (void)wait {
    dispatch_group_wait(self.group, DISPATCH_TIME_FOREVER);
}

@end
