#import "WMFImageController+Testing.h"

#import <SDWebImage/SDWebImage.h>
#import "WMFRandomFileUtilities.h"

@implementation WMFImageController (Testing)

+ (instancetype)temporaryController {
    SDImageCache *tempCache = [[SDImageCache alloc] initWithNamespace:@"temp" diskCacheDirectory:WMFRandomTemporaryPath()];
    SDWebImageManager *manager = [[SDWebImageManager alloc] initWithCache:tempCache downloader:[[SDWebImageDownloader alloc] init]];
    return [[WMFImageController alloc] initWithManager:manager namespace:@"temp"];
}

@end
