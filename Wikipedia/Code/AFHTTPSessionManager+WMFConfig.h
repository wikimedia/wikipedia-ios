#import <AFNetworking/AFNetworking.h>

@interface AFHTTPSessionManager (WMFConfig)

/**
 * Create a new instance configured with WMF application settings:
 * - proprietary request headers
 * - JSON response serializer
 */
+ (instancetype)wmf_createDefaultManager;

+ (instancetype)wmf_createIgnoreCacheManager;

@end
