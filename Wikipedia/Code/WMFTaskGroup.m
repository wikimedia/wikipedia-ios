#import "WMFTaskGroup.h"

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

- (void)waitInBackgroundWithCompletion:(nonnull dispatch_block_t)completion {
    dispatch_group_notify(self.group, dispatch_get_main_queue(), completion);
}

- (void)waitInBackgroundWithTimeout:(NSTimeInterval)timeout completion:(nonnull dispatch_block_t)completion {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_group_wait(self.group, time);
        completion();
    });
}

@end
