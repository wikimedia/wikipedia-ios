//
//  MWKImageGalleryViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWKArticle;

/// View controller which renders an article's images in a fullscreen, scrollable gallery.
@interface WMFImageGalleryViewController : UICollectionViewController

/// The article whose images are being displayed.
@property (nonatomic, readonly) MWKArticle* article;

/// Index of the currently visible image within the article's images.
@property (nonatomic) NSUInteger visibleImageIndex;

/**
 * Designated initializer.
 * @param article The article which will be the source of images for the gallery.
 * @return A new @c MWKImageGalleryViewController.
 */
- (instancetype)initWithArticle:(MWKArticle*)article;

- (void)setVisibleImage:(MWKImage*)visibleImage animated:(BOOL)animated;

- (void)setVisibleImageIndex:(NSUInteger)visibleImageIndex animated:(BOOL)animated;

@end
