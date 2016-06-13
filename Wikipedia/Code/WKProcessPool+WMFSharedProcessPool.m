#import "WKProcessPool+WMFSharedProcessPool.h"

@implementation WKProcessPool (WMFSharedProcessPool)

+ (WKProcessPool*)wmf_sharedProcessPool {
    static WKProcessPool* WMFSharedProcessPool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        WMFSharedProcessPool = [[WKProcessPool alloc] init];
    });
    return WMFSharedProcessPool;
}

@end
