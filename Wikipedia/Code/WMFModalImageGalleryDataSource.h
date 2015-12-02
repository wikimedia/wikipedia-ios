//
//  WMFModalImageGalleryDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFImageGalleryDataSource.h"

@class MWKImageInfo;
@protocol WMFModalImageGalleryDataSource;

@protocol WMFModalImageGalleryDataSourceDelegate <NSObject>

- (void)modalGalleryDataSource:(id<WMFModalImageGalleryDataSource>)dataSource didFailWithError:(NSError*)error;

- (void)modalGalleryDataSource:(id<WMFModalImageGalleryDataSource>)dataSource updatedItemsAtIndexes:(NSIndexSet*)indexes;

@end


@protocol WMFModalImageGalleryDataSource <WMFImageGalleryDataSource>

@property (nonatomic, weak, readwrite) id<WMFModalImageGalleryDataSourceDelegate> delegate;

- (MWKImageInfo*)imageInfoAtIndexPath:(NSIndexPath*)indexPath;

- (void)prefetchDataNearIndexPath:(NSIndexPath*)indexPath;

@end
