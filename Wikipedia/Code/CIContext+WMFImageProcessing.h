#import <CoreImage/CoreImage.h>

@interface CIContext (WMFImageProcessing)

+ (instancetype)wmf_sharedGPUContext;
+ (instancetype)wmf_sharedCPUContext;

@end
