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

///
/// @name Initialization
///
/// Initialize the gallery with these methods, not @c init (private use only).
///

/**
 *  Initialize a modal gallery with images from a <b>cached</b> article
 *
 *  This initializer is intended for cached articles.  If the article isn't cached but another is on the way, use
 *  @c initWithImagesInFutureArticle:placeholder: instead.
 *
 *  @param article      The article whose images will be displayed in the gallery.
 *  @param currentImage The image which should be visible when the gallery is presented.
 *
 *  @return A new modal image gallery which will display the images in @c article.
 */
- (instancetype)initWithImagesInArticle:(MWKArticle*)article
                           currentImage:(nullable MWKImage*)currentImage;

/**
 *  Initialize a modal gallery which will display the last several pictures of the day, including the given date.
 *
 *  @param info The info which was already downloaded to display picture of the day in the Home view.
 *
 *  @return A new modal image gallery which will display pictures of the day.
 */
- (instancetype)initWithInfo:(MWKImageInfo*)info forDate:(NSDate*)date;

///
/// @name Setting the delegate
///

/**
 * The gallery's delegate.
 *
 * Only necessary if extra work needs to be done when the gallery is dismissed or it wasn't presented modally.
 *
 * @see WMFImageGalleryViewControllerDelegate.
 */
@property (nonatomic, weak, nullable) id<WMFImageGalleryViewControllerDelegate> delegate;

///
/// @name Unsupoorted Initializers
///

- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithNibName:(nullable NSString*)nibNameOrNil
                         bundle:(nullable NSBundle*)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout*)layout NS_UNAVAILABLE;


- (UIImageView*)imageViewForImage:(MWKImage*)image;

- (UIImageView*)imageViewForIndexPath:(NSIndexPath*)indexPath;

@end

NS_ASSUME_NONNULL_END
