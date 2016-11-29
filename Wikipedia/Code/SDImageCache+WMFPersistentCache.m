#import "SDImageCache+WMFPersistentCache.h"

@implementation SDImageCache (WMFPersistentCache)

+ (NSString *)wmf_cacheDirectory {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *cacheDirectory = [[fm wmf_containerPath] stringByAppendingPathComponent:@"Cache"];
    NSError *cacheDirectoryError = nil;
    if (![fm createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:&cacheDirectoryError]) {
        DDLogError(@"Error creating cache directory %@", cacheDirectoryError);
    }
    return cacheDirectory;
}

+ (NSString *)wmf_imageCacheDirectory {
    return [[self wmf_cacheDirectory] stringByAppendingPathComponent:@"com.hackemist.SDWebImageCache.default"];
}

+ (NSString *)wmf_legacyImageCacheDirectory {
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    return [appSupportDir stringByAppendingPathComponent:@"com.hackemist.SDWebImageCache.default"];
}

+ (BOOL)migrateToSharedContainer:(NSError **)error {
    NSError *moveError = nil;
    if (![[NSFileManager defaultManager] moveItemAtPath:[self wmf_legacyImageCacheDirectory] toPath:[self wmf_imageCacheDirectory] error:&moveError]) {
        if (moveError.code != NSFileNoSuchFileError && moveError.code != NSFileReadNoSuchFileError) {
            if (error) {
                *error = moveError;
            }
            return NO;
        }
    }
    return YES;
}

+ (instancetype)wmf_cacheWithNamespace:(NSString *)ns {

    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:ns inDirectory:[SDImageCache wmf_cacheDirectory]];

    NSString *fullPath = [cache defaultCachePathForKey:@"bogus"];
    fullPath = [fullPath stringByDeletingLastPathComponent];
    NSURL *directoryURL = [NSURL fileURLWithPath:fullPath isDirectory:YES];
    NSError *excludeBackupError = nil;
    [directoryURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&excludeBackupError];
    if (excludeBackupError) {
        DDLogError(@"Error excluding from backup: %@", excludeBackupError);
    }

    cache.maxMemoryCountLimit = 50;
    return cache;
}

@end
