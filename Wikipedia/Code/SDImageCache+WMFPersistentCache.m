//
//  SDImageCache+WMFPersistentCache.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "SDImageCache+WMFPersistentCache.h"

@implementation SDImageCache (WMFPersistentCache)

+ (instancetype)wmf_appSupportCacheWithNamespace:(NSString*)ns {
    NSString* appSupportDir =
        [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSParameterAssert(appSupportDir.length);

    SDImageCache* cache = [[SDImageCache alloc] initWithNamespace:ns inDirectory:appSupportDir];

    NSString* fullPath = [cache defaultCachePathForKey:@"bogus"];
    fullPath = [fullPath stringByDeletingLastPathComponent];
    NSURL* directoryURL         = [NSURL fileURLWithPath:fullPath isDirectory:YES];
    NSError* excludeBackupError = nil;
    [directoryURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&excludeBackupError];
    if (excludeBackupError) {
        DDLogError(@"Error excluding from backup: %@", excludeBackupError);
    }

    cache.maxMemoryCountLimit = 50;
    return cache;
}

@end
