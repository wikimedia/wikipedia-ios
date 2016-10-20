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

@end
