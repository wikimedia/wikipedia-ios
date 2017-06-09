@import Foundation;

@interface WMFLegacyImageCache : NSObject

+ (nullable NSString *)cachePathForKey:(nullable NSString *)key inPath:(nonnull NSString *)path;

@end
