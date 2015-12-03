//
//  WMFArticleImageDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/10/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFImageGalleryDataSource.h"
#import <SSDataSources/SSArrayDataSource.h>

@class MWKArticle, MWKImage;

/**
 *  Base data source for galleries which display images in an article.
 *
 *  This class has a few responsibilities which are required to display article images in a gallery:
 *
 *  <h4>Collapsing variants in the gallery</h4>
 *
 *  Populates the collection view with distinct instances of the images in the article. In other words, uses
 *  @c uniqueArticleImages to get a unique list of images in their original order.  The images displayed in the gallery
 *  are the largest variants of each image (e.g. any additional entries extracted from srcset).
 *
 *  <h4>Empty View</h4>
 *
 *  Provides an "empty view" of the articles lead image (or thumbnail) if there aren't any images (e.g. if the article
 *  was just a preview whose data hasn't been downloaded yet).
 *
 *  <h4>RTL Handling</h4>
 *
 *  This class also implements RTL handling by reversing the items as needed.
 */
@interface WMFArticleImageGalleryDataSource : SSArrayDataSource
    <WMFImageGalleryDataSource>

- (instancetype)initWithArticle:(MWKArticle*)article;

/**
 *  The article whose images should populate the collection view.
 */
@property (nonatomic, strong, readonly) MWKArticle* article;

/**
 *  @return The source URL of the largest variant of the image at @c indexPath.
 */
- (MWKImage*)imageAtIndexPath:(NSIndexPath*)indexPath;

///
/// @name Unsupported Initializers

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTarget:(id)target keyPath:(NSString*)keyPath NS_UNAVAILABLE;
- (instancetype)initWithItems:(NSArray*)items NS_UNAVAILABLE;

@end
