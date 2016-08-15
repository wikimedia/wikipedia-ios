//
//  SDImageCache+WMFPersistentCache.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <SDWebImage/SDImageCache.h>

@interface SDImageCache (WMFPersistentCache)

+ (instancetype)wmf_appSupportCacheWithNamespace:(NSString *)ns;

@end
