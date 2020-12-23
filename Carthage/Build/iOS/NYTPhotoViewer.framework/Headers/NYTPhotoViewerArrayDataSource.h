//
//  NYTPhotoViewerArrayDataSource.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/11/15.
//  Copyright (c) 2017 The New York Times Company. All rights reserved.
//

@import Foundation;

#import "NYTPhotoViewerDataSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A simple concrete implementation of `NYTPhotoViewerDataSource`, for use with an array of images.
 *  Does not support interstitial views.
 */
@interface NYTPhotoViewerArrayDataSource : NSObject <NYTPhotoViewerDataSource, NSFastEnumeration>

@property (nonatomic, readonly) NSArray<id<NYTPhoto>> *photos;

/**
 *  The designated initializer that takes and stores an array of photos.
 *
 *  @param photos An array of objects conforming to the `NYTPhoto` protocol.
 *
 *  @return A fully initialized data source.
 */
- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto>> *)photos NS_DESIGNATED_INITIALIZER;

+ (instancetype)dataSourceWithPhotos:(nullable NSArray<id<NYTPhoto>> *)photos;

- (id<NYTPhoto>)objectAtIndexedSubscript:(NSUInteger)idx;

@end

NS_ASSUME_NONNULL_END
