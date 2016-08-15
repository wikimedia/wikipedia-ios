//
//  SDWebImageManager+WMFCacheRemoval.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <SDWebImage/SDWebImageManager.h>

@interface SDWebImageManager (WMFCacheRemoval)

- (void)wmf_removeImageForURL:(NSURL *__nullable)URL fromDisk:(BOOL)fromDisk;

- (void)wmf_removeImageURLs:(NSArray *__nonnull)URLs fromDisk:(BOOL)fromDisk;

@end
