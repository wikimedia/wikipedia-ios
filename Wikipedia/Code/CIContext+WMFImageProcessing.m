@import CoreImage;

@implementation CIContext (WMFImageProcessing)

+ (instancetype)wmf_sharedGPUContext {
    static CIContext *sharedContext;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *options = @{
            kCIContextPriorityRequestLow: @YES
        };
        sharedContext = [CIContext contextWithOptions:options];
    });
    return sharedContext;
}

+ (instancetype)wmf_sharedCPUContext {
    static CIContext *sharedContext;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *options = @{
            kCIContextPriorityRequestLow: @YES,
            kCIContextUseSoftwareRenderer: @YES
        };
        sharedContext = [CIContext contextWithOptions:options];
    });
    return sharedContext;
}

@end
