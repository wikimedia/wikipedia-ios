//
//  WMFModalArticleImageGalleryViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFModalImageGalleryViewController.h"

@class MWKImage;
@class MWKArticle;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Displays a modal gallery of images for a given article.
 *
 *  Uses a special data source which handles extracting images from an article object, and fetching their metadata.
 */
@interface WMFModalArticleImageGalleryViewController : WMFModalImageGalleryViewController

/**
 *  Specify the image to be displayed when the receiver appears.
 *
 *  @param visibleImage The image which should be displayed, e.g. the image a user selected in the article view.
 *  @param animated     Whether or not to scroll to the image with an animation.
 */
- (void)setVisibleImage:(MWKImage*)visibleImage animated:(BOOL)animated;

/**
 *  Resets the receiver with a new data source which is populated with images in the given article.
 *
 *  @param article The article whose images to display, or @c nil to empty the gallery.
 */
- (void)showImagesInArticle:(nullable MWKArticle*)article;

/**
 *  Set an article for the gallery in the future.
 *
 *  Called when the user taps on an article's lead image before the article data has finished downloading. This will
 *  show the gallery (empty) with a loading indicator, and then load itself when the data has finished downloading.
 *
 *  @param articlePromise Promise which resolves to an `MWKArticle`.
 */
- (void)setArticleWithPromise:(AnyPromise*)articlePromise;

@end

NS_ASSUME_NONNULL_END
