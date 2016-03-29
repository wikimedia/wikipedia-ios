
#import <AFNetworking/AFNetworking.h>

@interface AFHTTPSessionManager (WMFConfig)

/**
 * Create a new instance configured with WMF application settings:
 * - proprietary request headers
 * - JSON response serializer
 */
+ (instancetype)wmf_createDefaultManager;

/// Configure the receiver to use WMF proprietary request headers.
- (void)wmf_applyAppRequestHeaders;

@end
