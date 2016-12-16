#import "NSURL+WMFProxyServer.h"

NSString *const WMFProxyImageOriginalSrcKey = @"originalSrc";
NSString *const WMFProxyImageBaseURLKey = @"baseURL";
NSString *const WMFProxyImageBasePath = @"imageProxy";
NSString *const WMFProxyFileBasePath = @"fileProxy";

@implementation NSURL (WMFProxyServer)

- (nullable NSURL *)wmf_imageProxyOriginalSrcURL {
    return [NSURL URLWithString:[self wmf_valueForQueryKey:WMFProxyImageOriginalSrcKey]];
}

- (NSURL *)wmf_imageProxyURLWithOriginalSrc:(NSString *)originalSrc {
    return [self wmf_urlWithValue:originalSrc forQueryKey:WMFProxyImageOriginalSrcKey];
}

@end
