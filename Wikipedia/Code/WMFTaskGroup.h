#import <Foundation/Foundation.h>

@interface WMFTaskGroup : NSObject

- (void)enter;
- (void)leave;

- (void)waitInBackgroundWithCompletion:(nonnull dispatch_block_t)completion;

@end
