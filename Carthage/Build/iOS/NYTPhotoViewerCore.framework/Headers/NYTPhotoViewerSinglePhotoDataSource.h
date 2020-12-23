//
//  NYTPhotoViewerSinglePhotoDataSource.h
//  NYTPhotoViewer
//
//  Created by Chris Dzombak on 1/27/17.
//  Copyright © 2017 The New York Times Company. All rights reserved.
//

@import Foundation;

#import "NYTPhotoViewerDataSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A simple concrete implementation of `NYTPhotoViewerDataSource`, for use with a single image.
 */
@interface NYTPhotoViewerSinglePhotoDataSource : NSObject <NYTPhotoViewerDataSource>

@property (nonatomic, readonly) id<NYTPhoto> photo;

/**
 *  The designated initializer that takes and stores a single photo.
 *
 *  @param photo An object conforming to the `NYTPhoto` protocol.
 *
 *  @return A fully initialized data source.
 */
- (instancetype)initWithPhoto:(id<NYTPhoto>)photo NS_DESIGNATED_INITIALIZER;

+ (instancetype)dataSourceWithPhoto:(id<NYTPhoto>)photo;

/**
 *  Initializing without a photo is invalid.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
