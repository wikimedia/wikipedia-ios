#import "AFHTTPSessionManager+WMFConfig.h"
#import "AFHTTPRequestSerializer+WMFRequestHeaders.h"

@implementation AFHTTPSessionManager (WMFConfig)

+ (instancetype)wmf_createDefaultManager {
    AFHTTPSessionManager *manager = [self manager];
    [manager.requestSerializer wmf_applyAppRequestHeaders];
    return manager;
}

@end
