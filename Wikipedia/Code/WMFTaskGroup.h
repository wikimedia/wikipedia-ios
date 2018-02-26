@import Foundation;

@interface WMFTaskGroup : NSObject

- (void)enter;
- (void)leave;

- (void)waitInBackgroundAndNotifyOnQueue:(nonnull dispatch_queue_t)queue withBlock:(nonnull dispatch_block_t)block;

- (void)waitInBackgroundWithCompletion:(nonnull dispatch_block_t)completion;

- (void)waitInBackgroundWithTimeout:(NSTimeInterval)timeout completion:(nonnull dispatch_block_t)completion;

- (void)waitWithTimeout:(NSTimeInterval)timeout;

- (void)wait;

@end
