#import "WMFImageController+Testing.h"

#import <SDWebImage/SDWebImage.h>
#import "WMFRandomFileUtilities.h"

@implementation WMFImageController (Testing)

+ (instancetype)temporaryController {
    SDImageCache *tempCache = [[SDImageCache alloc] initWithNamespace:@"temp" inDirectory:WMFRandomTemporaryPath()];
    SDWebImageManager *manager = [[SDWebImageManager alloc] initWithDownloader:[[SDWebImageDownloader alloc] init]
                                                                         cache:tempCache];
    return [[WMFImageController alloc] initWithManager:manager namespace:@"temp"];
}

@end
