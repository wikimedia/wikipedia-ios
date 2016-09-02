#import <AFNetworking/AFNetworking.h>

@interface AFHTTPSessionManager (WMFCancelAll)

- (void)wmf_cancelAllTasks;

- (void)wmf_cancelAllTasksWithCompletionHandler:(dispatch_block_t)completion;

@end
