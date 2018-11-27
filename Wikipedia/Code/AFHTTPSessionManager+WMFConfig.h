@import AFNetworking;

NS_ASSUME_NONNULL_BEGIN

@interface AFHTTPSessionManager (WMFConfig)

/**
 * Create a new instance configured with WMF application settings:
 * - proprietary request headers
 * - JSON response serializer
 */
+ (instancetype)wmf_createDefaultManager;

@end

NS_ASSUME_NONNULL_END
