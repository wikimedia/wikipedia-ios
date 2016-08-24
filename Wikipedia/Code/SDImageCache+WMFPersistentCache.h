#import <SDWebImage/SDImageCache.h>

@interface SDImageCache (WMFPersistentCache)

+ (instancetype)wmf_cacheWithNamespace:(NSString *)ns;

+ (BOOL)migrateToSharedContainer:(NSError **)error;

@end
