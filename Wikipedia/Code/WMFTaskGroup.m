#import "WMFTaskGroup.h"

@interface WMFTaskGroup ()

@property(nonatomic) dispatch_group_t group;
@property(nonatomic) NSInteger count;

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

@end
