//
//  WMFModalPOTDGalleryDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <SSDataSources/SSArrayDataSource.h>
#import "WMFModalImageGalleryDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFModalPOTDGalleryDataSource : SSArrayDataSource
    <WMFModalImageGalleryDataSource>

- (instancetype)initWithInfo:(MWKImageInfo*)info forDate:(NSDate*)date NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
