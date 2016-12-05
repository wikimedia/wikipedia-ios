#import <WebImage/WebImage.h>

@interface SDImageCache (WMFPersistentCache)

+ (NSString *)wmf_imageCacheDirectory;

+ (instancetype)wmf_cacheWithNamespace:(NSString *)ns;

+ (BOOL)migrateToSharedContainer:(NSError **)error;

@end
