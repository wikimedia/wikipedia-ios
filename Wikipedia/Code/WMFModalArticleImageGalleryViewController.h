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
 */
@interface WMFModalArticleImageGalleryViewController : WMFModalImageGalleryViewController

- (void)setVisibleImage:(MWKImage*)visibleImage animated:(BOOL)animated;

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
