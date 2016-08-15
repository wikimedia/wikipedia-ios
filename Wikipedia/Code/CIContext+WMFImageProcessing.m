@implementation CIContext (WMFImageProcessing)

+ (instancetype)wmf_sharedContext {
  static CIContext *sharedContext;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSDictionary *options = @{ kCIContextPriorityRequestLow : @YES };
    sharedContext = [CIContext contextWithOptions:options];
  });
  return sharedContext;
}

@end
