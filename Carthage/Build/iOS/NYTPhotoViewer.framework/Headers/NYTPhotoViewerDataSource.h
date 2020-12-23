//
//  NYTPhotosViewControllerDataSource.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/10/15.
//  Copyright (c) 2015 NYTimes. All rights reserved.
//

@import UIKit;

@protocol NYTPhoto;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The data source for an `NYTPhotosViewController` instance.
 *
 *  A view controller, view model, or model in your application could conform to this protocol, depending on what makes sense in your architecture.
 *
 *  Alternatively, `NYTPhotoViewerArrayDataSource` and `NYTPhotoViewerSinglePhotoDataSource` are concrete classes which conveniently handle the most common use cases for NYTPhotoViewer.
 */
@protocol NYTPhotoViewerDataSource <NSObject>

/**
 *  The total number of photos in the data source, or `nil` if the number is not known.
 *
 *  The number returned should package an `NSInteger` value.
 */
@property (nonatomic, readonly, nullable) NSNumber *numberOfPhotos;

/**
 *  Returns the index of a given photo, or `NSNotFound` if the photo is not in the data source.
 *
 *  @param photo The photo against which to look for the index.
 *
 *  @return The index of a given photo, or `NSNotFound` if the photo is not in the data source.
 */
- (NSInteger)indexOfPhoto:(id <NYTPhoto>)photo;

/**
 *  Returns the photo object at a specified index, or `nil` if one does not exist at that index.
 *
 *  @param photoIndex The index of the desired photo.
 *
 *  @return The photo object at a specified index, or `nil` if one does not exist at that index.
 */
- (nullable id <NYTPhoto>)photoAtIndex:(NSInteger)photoIndex;

@optional

/**
 *  The total number of interstitial views in the data source.
 *
 *  The number returned should package an `NSInteger` value.
 *
 *  @return The number of interstitial views or `nil` if the number is not known.
 */
- (NSNumber *)numberOfInterstitialViews;

/**
 *  Indicates if the item at the specified index is a photo.
 *
 *  @return `true` if the item at the specified index is a photo, `false` otherwise.
 */
- (BOOL)isPhotoAtIndex:(NSInteger)idx;

/**
 *  Indicates if the item at the specified index is an interstitial view.
 *
 *  @return `true` if the item at the specified index is an interstitial view, `false` otherwise.
 */
- (BOOL)isInterstitialViewAtIndex:(NSInteger)idx;

@end

NS_ASSUME_NONNULL_END
