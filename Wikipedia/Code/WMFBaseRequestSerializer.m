#import "WMFBaseRequestSerializer.h"

@implementation WMFBaseRequestSerializer

- (instancetype)init {
    self = [super init];
    if (self) {
        [self wmf_applyAppRequestHeaders];
    }
    return self;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters error:(NSError *__autoreleasing _Nullable *)error {
    NSMutableURLRequest *mutableRequest = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    mutableRequest.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    return mutableRequest;
}

@end
