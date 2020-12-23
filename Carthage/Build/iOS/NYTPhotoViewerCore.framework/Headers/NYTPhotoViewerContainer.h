//
//  NYTPhotoViewerContainer.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/11/15.
//
//

@protocol NYTPhoto;

/**
 *  A protocol that defines that an object contains a photo or interstitial view property
 *  and the index of the item in the collection.
 */
@protocol NYTPhotoViewerContainer <NSObject>

/**
 *  An object conforming to the `NYTPhoto` protocol.
 *  Will be nil if the container has a view.
 */
@property (nonatomic, readonly, nullable) id <NYTPhoto> photo;

/**
 *  A view to be displayed instead of a photo.
 *  Will be nil if the container has a photo.
 */
@property (nonatomic, readonly, nullable) UIView *interstitialView;

/**
 *  The index of this item in the collection.
 */

@property (nonatomic, readonly) NSUInteger photoViewItemIndex;

@end
