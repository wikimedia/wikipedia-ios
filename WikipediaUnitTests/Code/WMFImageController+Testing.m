//
//  WMFImageController+Testing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageController+Testing.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDImageCache.h>
#import "WMFRandomFileUtilities.h"

@implementation WMFImageController (Testing)

+ (instancetype)temporaryController {
    SDImageCache *tempCache = [[SDImageCache alloc] initWithNamespace:@"temp" inDirectory:WMFRandomTemporaryPath()];
    SDWebImageManager *manager = [[SDWebImageManager alloc] initWithDownloader:[[SDWebImageDownloader alloc] init]
                                                                         cache:tempCache];
    return [[WMFImageController alloc] initWithManager:manager namespace:@"temp"];
}

@end
