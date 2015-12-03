//
//  MWKImageGalleryViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WMFBaseImageGalleryViewController.h"
#import "Wikipedia-Swift.h"

@class MWKArticle, MWKImage, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@class WMFModalImageGalleryViewController;
@protocol WMFImageGalleryViewControllerDelegate <NSObject>

@optional

/**
 * Optional. Called when a gallery's close button is tapped before it is dismissed.
 *
 * @param gallery The gallery being dismissed.
 */
- (void)willDismissGalleryController:(WMFModalImageGalleryViewController*)gallery;

/**
 * Optional. Called when a gallery's close button is tapped before it is dismissed.
 *
 * @param gallery The gallery being dismissed.
 */
- (void)didDismissGalleryController:(WMFModalImageGalleryViewController*)gallery;

@end

/**
 *  Provides a scrollable gallery of high-resolution images and their associated metadata.
 *
 *  This class is intended to provide a consistent, modal gallery experience for any source of images. It does this with:
 *
 *  * Using a paging collection view to allow users to swipe though items
 *
 *  * Using special collection view cells (see @c WMFImageGalleryCollectionViewCell)
 *
 *  * Overlaying a "chrome" UI on top of the collection view (close button & top gradient)
 *
 *  * Interacting with its @c dataSource at specific points to allow for display of placeholder images, and elegantly
 *    updating cells when metadata and higher-resolution images are available.
 */
@interface WMFModalImageGalleryViewController : WMFBaseImageGalleryViewController

/**
 *  Initialize a new modal gallery with its specialized layout.
 *
 *  @return A new modal gallery view controller.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * The gallery's delegate.
 *
 * Only necessary if extra work needs to be done when the gallery is dismissed or it wasn't presented modally.
 *
 * @see WMFImageGalleryViewControllerDelegate.
 */
@property (nonatomic, weak, nullable) id<WMFImageGalleryViewControllerDelegate> delegate;

/**
 * Controls whether auxilliary image information and controls are visible (e.g. close button & image metadata).
 *
 * Set to `YES` to hide image metadata, close button, and gradients. Only has an effect if `chromeEnabled` is `YES`.
 *
 * @see chromeEnabled
 */
@property (nonatomic, getter = isChromeHidden) BOOL chromeHidden;

/**
 *  Toggle the display of the chrome UI.
 *
 *  Subclasses shouldn't need to call this, as @c WMFModalImageGalleryViewController already implements gesture
 *  recognition to allow users to toggle the state.
 *
 *  @param hidden   The desired state.
 *  @param animated Whether the transition to @c hidden should be animated.
 */
- (void)setChromeHidden:(BOOL)hidden animated:(BOOL)animated;

///
/// @name Unsupoorted Initializers
///

/// @see init
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

/// @see init
- (instancetype)initWithNibName:(nullable NSString*)nibNameOrNil
                         bundle:(nullable NSBundle*)nibBundleOrNil NS_UNAVAILABLE;

/// @see init
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout*)layout NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
