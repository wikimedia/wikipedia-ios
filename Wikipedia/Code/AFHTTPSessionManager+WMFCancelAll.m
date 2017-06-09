#import <WMF/AFHTTPSessionManager+WMFCancelAll.h>

@implementation AFHTTPSessionManager (WMFCancelAll)

- (void)wmf_cancelAllTasks {
    [self wmf_cancelAllTasksWithCompletionHandler:NULL];
}

- (void)wmf_cancelAllTasksWithCompletionHandler:(dispatch_block_t)completion {
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *_Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> *_Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> *_Nonnull downloadTasks) {
        NSMutableArray<NSURLSessionTask *> *all = [NSMutableArray arrayWithArray:dataTasks];
        [all addObjectsFromArray:uploadTasks];
        [all addObjectsFromArray:downloadTasks];
        [all enumerateObjectsUsingBlock:^(NSURLSessionTask *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [obj cancel];
        }];

        if (completion) {
            completion();
        }
    }];
}

@end
