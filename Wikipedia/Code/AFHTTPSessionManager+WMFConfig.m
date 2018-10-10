#import <WMF/AFHTTPSessionManager+WMFConfig.h>
#import <WMF/WMFBaseRequestSerializer.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation AFHTTPSessionManager (WMFConfig)

+ (instancetype)wmf_createDefaultManager {
    NSURLSessionConfiguration *config = [WMFSession defaultConfiguration];
    AFHTTPSessionManager *manager =[[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    manager.requestSerializer = [WMFBaseRequestSerializer serializer];

    NSMutableIndexSet *set = [manager.responseSerializer.acceptableStatusCodes mutableCopy];
    [set addIndex:304];
    manager.responseSerializer.acceptableStatusCodes = set;
    return manager;
}

+ (instancetype)wmf_createIgnoreCacheManager {
    NSURLSessionConfiguration *config = [WMFSession defaultConfiguration];
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    manager.requestSerializer = [WMFBaseRequestSerializer serializer];
    return manager;
}

@end

NS_ASSUME_NONNULL_END
