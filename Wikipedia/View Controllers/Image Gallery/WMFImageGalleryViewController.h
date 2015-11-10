//
//  MWKImageGalleryViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WMFPageCollectionViewController.h"
#import "Wikipedia-Swift.h"

@class MWKArticle, MWKImage;

NS_ASSUME_NONNULL_BEGIN

@class WMFImageGalleryViewController;
@protocol WMFImageGalleryViewControllerDelegate <NSObject>

@optional

/**
 * Optional. Called when a gallery's close button is tapped before it is dismissed.
 *
 * @param gallery The gallery being dismissed.
 */
- (void)willDismissGalleryController:(WMFImageGalleryViewController*)gallery;

/**
 * Optional. Called when a gallery's close button is tapped before it is dismissed.
 *
 * @param gallery The gallery being dismissed.
 */
- (void)didDismissGalleryController:(WMFImageGalleryViewController*)gallery;

@end

/**
 *  Provides a scrollable gallery of an article's images, including high-res, zoomable images and associated metadata.
 */
@interface WMFImageGalleryViewController : WMFPageCollectionViewController

/**
 * The article whose images are being displayed.
 *
 * Set to `nil` to empty the gallery.
 */
@property (nonatomic, strong, nullable) MWKArticle* article;

/**
 *  Set an article for the gallery in the future.
 *
 *  Called when the user taps on an article's lead image before the article data has finished downloading. This will
 *  show the gallery (empty) with a loading indicator, and then load itself when the data has finished downloading.
 *
 *  @param articlePromise Promise which resolves to an `MWKArticle`.
 */
- (void)setArticleWithPromise:(AnyPromise*)articlePromise;

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
 * Whether or not chrome UI is able to be shown.
 *
 * Defaults to `YES`. Set to `NO` to both hide the chrome and prevent it from being shown.
 *
 * @see chromeHidden
 */
@property (nonatomic, getter = isChromeEnabled) BOOL chromeEnabled;

/**
 * Controls whether or not the user is allowed to pan or zoom images.
 *
 * Defaults to `YES`.
 */
@property (nonatomic, getter = isZoomEnabled) BOOL zoomEnabled;

/**
 * Initialize an instance with the given article.
 * @param article The article which will be the source of images for the gallery.
 * @return A new @c MWKImageGalleryViewController.
 */
- (instancetype)initWithArticle:(MWKArticle* __nullable)article NS_DESIGNATED_INITIALIZER;

- (void)setVisibleImage:(MWKImage*)visibleImage animated:(BOOL)animated;

- (void)setChromeHidden:(BOOL)hidden animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
