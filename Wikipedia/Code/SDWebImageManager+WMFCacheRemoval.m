//
//  SDWebImageManager+WMFCacheRemoval.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "SDWebImageManager+WMFCacheRemoval.h"

#if DEBUG
#define LOG_POST_REMOVAL_CACHE_SIZE 1
#else
#define LOG_POST_REMOVAL_CACHE_SIZE 0
#endif

@implementation SDWebImageManager (WMFCacheRemoval)

- (void)wmf_removeImageForURL:(NSURL *__nullable)URL fromDisk:(BOOL)fromDisk {
#if LOG_POST_REMOVAL_CACHE_SIZE
    DDLogVerbose(@"Removing image with URL %@ from cache. Current size: %lu", URL, (unsigned long)[self.imageCache getSize]);
    @weakify(self)
#endif
        [self.imageCache removeImageForKey:[self cacheKeyForURL:URL]
                                  fromDisk:fromDisk
                            withCompletion:
#if LOG_POST_REMOVAL_CACHE_SIZE
                                ^{
                                  @strongify(self)
                                      [self wmf_calculateAndLogCacheSize];
                                }
#else
                            nil
#endif
    ];
}

- (void)wmf_removeImageURLs:(NSArray *__nonnull)URLs fromDisk:(BOOL)fromDisk {
#if LOG_POST_REMOVAL_CACHE_SIZE
    DDLogVerbose(@"Cache size is %lu before removing image URLs: %@", (unsigned long)[self.imageCache getSize], URLs);
#endif
    for (NSURL *url in URLs) {
        NSAssert([url isKindOfClass:[NSURL class]], @"Unexpected value in image URL array: %@", url);
        [self.imageCache removeImageForKey:[self cacheKeyForURL:url] fromDisk:fromDisk];
    }
#if LOG_POST_REMOVAL_CACHE_SIZE
    [self wmf_calculateAndLogCacheSize];
#endif
}

#if LOG_POST_REMOVAL_CACHE_SIZE
- (void)wmf_calculateAndLogCacheSize {
    [self.imageCache calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
      DDLogInfo(@"Current cache size:\n"
                 "\t- files: %lu\n"
                 "\t- totalSize: %lu\n",
                (unsigned long)fileCount,
                (unsigned long)totalSize);
    }];
}

#endif

@end
