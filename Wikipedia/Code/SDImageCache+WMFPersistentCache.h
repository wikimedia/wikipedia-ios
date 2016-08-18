#import <SDWebImage/SDImageCache.h>

@interface SDImageCache (WMFPersistentCache)

+ (instancetype)wmf_appSupportCacheWithNamespace:(NSString*)ns;

@end
