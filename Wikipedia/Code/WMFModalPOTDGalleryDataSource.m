//
//  WMFModalPOTDGalleryDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFModalPOTDGalleryDataSource.h"
#import "MWKImageInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFModalPOTDGalleryDataSource ()

@property (nonatomic, strong) NSMutableDictionary<NSDate*, MWKImageInfo*>* info;

@end

@implementation WMFModalPOTDGalleryDataSource
@synthesize delegate;

- (instancetype)initWithInfo:(MWKImageInfo*)info forDate:(NSDate*)date {
    self = [super initWithItems:@[date]];
    if (self) {
        self.info = [NSMutableDictionary dictionaryWithObject:info forKey:date];
    }
    return self;
}

- (NSURL*)imageURLAtIndexPath:(NSIndexPath*)indexPath {
    return [[self imageInfoAtIndexPath:indexPath] imageThumbURL];
}

- (nullable MWKImageInfo*)imageInfoAtIndexPath:(NSIndexPath*)indexPath {
    // TODO: return high-res info for that index path
    NSDate* dateAtIndexPath = [self itemAtIndexPath:indexPath];
    return self.info[dateAtIndexPath];
}

- (void)prefetchDataNearIndexPath:(NSIndexPath*)indexPath {
    // soon...
}

@end

NS_ASSUME_NONNULL_END
