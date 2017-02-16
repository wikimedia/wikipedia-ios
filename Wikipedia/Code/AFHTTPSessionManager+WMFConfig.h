#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface AFHTTPSessionManager (WMFConfig)

/**
 * Create a new instance configured with WMF application settings:
 * - proprietary request headers
 * - JSON response serializer
 */
+ (instancetype)wmf_createDefaultManager;

+ (instancetype)wmf_createIgnoreCacheManager;

@end

NS_ASSUME_NONNULL_END
