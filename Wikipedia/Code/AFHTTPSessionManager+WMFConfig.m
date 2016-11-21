#import "AFHTTPSessionManager+WMFConfig.h"
#import "WMFBaseRequestSerializer.h"

@implementation AFHTTPSessionManager (WMFConfig)

+ (instancetype)wmf_createDefaultManager {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [WMFBaseRequestSerializer serializer];
    
    NSMutableIndexSet* set = [manager.responseSerializer.acceptableStatusCodes mutableCopy];
    [set addIndex:304];
    manager.responseSerializer.acceptableStatusCodes = set;
    return manager;
}


+ (instancetype)wmf_createIgnoreCacheManager{
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    manager.requestSerializer = [WMFBaseRequestSerializer serializer];
    return manager;
}


@end
