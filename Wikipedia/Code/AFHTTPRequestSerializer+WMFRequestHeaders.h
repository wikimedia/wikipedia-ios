#import <AFNetworking/AFNetworking.h>

@interface AFHTTPRequestSerializer (WMFRequestHeaders)

/// Configure the receiver to use WMF proprietary request headers.
- (void)wmf_applyAppRequestHeaders;

@end
