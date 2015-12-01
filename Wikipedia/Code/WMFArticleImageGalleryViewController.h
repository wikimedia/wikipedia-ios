//
//  WMFArticleImageGalleryViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseImageGalleryViewController.h"

@class MWKArticle;
@class WMFImageGalleryDataSource;

@interface WMFArticleImageGalleryViewController : WMFBaseImageGalleryViewController

- (WMFImageGalleryDataSource*)articleGalleryDataSource;

/**
 *  Causes the receiver to populate its UI with images in @c article.
 *
 *  If @c article is not cached, the receiver will attempt to show single image view with either @c article.image or
 *  @c article.thumbnailImage.
 *
 *  @param article The article whose images should be shown.
 */
- (void)showImagesInArticle:(MWKArticle*)article;

@end
