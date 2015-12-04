//
//  WMFModalImageGalleryDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFImageGalleryDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class MWKImageInfo;
@protocol WMFModalImageGalleryDataSource;

/**
 *  Delegate which is used to react to updates & errors from a @c WMFModalImageGalleryDataSource.
 */
@protocol WMFModalImageGalleryDataSourceDelegate <NSObject>

- (void)modalGalleryDataSource:(id<WMFModalImageGalleryDataSource>)dataSource didFailWithError:(NSError*)error;

- (void)modalGalleryDataSource:(id<WMFModalImageGalleryDataSource>)dataSource updatedItemsAtIndexes:(NSIndexSet*)indexes;

@end


/**
 *  Data source which drives a @c WMFModalImageGalleryViewController, providing more data (i.e. @c MWKImageInfo).
 */
@protocol WMFModalImageGalleryDataSource <WMFImageGalleryDataSource>

@property (nonatomic, weak, readwrite) id<WMFModalImageGalleryDataSourceDelegate> delegate;

- (nullable MWKImageInfo*)imageInfoAtIndexPath:(NSIndexPath*)indexPath;

- (void)fetchDataAtIndexPath:(NSIndexPath*)indexPath;

@end

NS_ASSUME_NONNULL_END
