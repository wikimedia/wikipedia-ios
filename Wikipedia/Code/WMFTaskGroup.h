#import <Foundation/Foundation.h>

@interface WMFTaskGroup : NSObject

- (void)enter;
- (void)leave;

- (void)waitInBackgroundWithTimeout:(NSTimeInterval)timeout completion:(nonnull dispatch_block_t)completion;

- (void)waitInBackgroundWithCompletion:(nonnull dispatch_block_t)completion;

@end
