#import <WebImage/WebImage.h>

@interface SDWebImageManager (WMFCacheRemoval)

- (void)wmf_removeImageForURL:(NSURL *__nullable)URL fromDisk:(BOOL)fromDisk;

- (void)wmf_removeImageURLs:(NSArray *__nonnull)URLs fromDisk:(BOOL)fromDisk;

@end
