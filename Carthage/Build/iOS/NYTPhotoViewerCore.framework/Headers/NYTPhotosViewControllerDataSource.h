//
//  NYTPhotosViewControllerDataSource.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/10/15.
//  Copyright (c) 2015 NYTimes. All rights reserved.
//

@import UIKit;

@protocol NYTPhoto;

/**
 *  A protocol defining methods that must exist on a data source for an `NYTPhotosViewController`.
 */
@protocol NYTPhotosViewControllerDataSource <NSFastEnumeration>

/**
 *  The total number of photos in the data source.
 */
@property (nonatomic, readonly) NSUInteger numberOfPhotos;

/**
 *  Returns the photo object at a specified index, or `nil` if one does not exist at that index.
 *
 *  @param photoIndex The index of the desired photo.
 *
 *  @return The photo object at a specified index, or `nil` if one does not exist at that index.
 */
- (id <NYTPhoto>)photoAtIndex:(NSUInteger)photoIndex;

/**
 *  Returns the index of a given photo, or `NSNotFound` if the photo is ot in the data source.
 *
 *  @param photo The photo against which to look for the index.
 *
 *  @return The index of a given photo, or `NSNotFound` if the photo is ot in the data source.
 */
- (NSUInteger)indexOfPhoto:(id <NYTPhoto>)photo;

/**
 *  Returns a `BOOL` representing whether the data source contains the passed-in photo.
 *
 *  @param photo The photo to check existence of in the data source.
 *
 *  @return A `BOOL` representing whether the data source contains the passed-in photo.
 */
- (BOOL)containsPhoto:(id <NYTPhoto>)photo;

/**
 *  Subscripting support. For example, `dataSource[0]` will be a valid way to obtain the photo at index 0.
 *  @note Indexes outside the range of the data source are expected to return `nil` and not to crash.
 *
 *  @param photoIndex The index of the photo.
 *
 *  @return The photo at the index, or `nil` if there is none.
 */
- (id <NYTPhoto>)objectAtIndexedSubscript:(NSUInteger)photoIndex;

@end
