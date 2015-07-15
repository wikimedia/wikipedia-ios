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
    return [[SDImageCache alloc] initWithNamespace:ns inDirectory:appSupportDir];
}

@end
