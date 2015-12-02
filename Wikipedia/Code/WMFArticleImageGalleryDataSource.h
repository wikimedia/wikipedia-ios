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
 *  Class which uses an article's images to populate collection view data.
 *
 *  @warning This class provides an empty image view which is set to the article's lead image or thumbnail.
 *           Do not reconfigure its @c emptyView property.
 */
@interface WMFArticleImageGalleryDataSource : SSArrayDataSource
<WMFImageGalleryDataSource>

/**
 *  The article whose images should populate the collection view.
 */
@property (nonatomic, strong) MWKArticle* article;

/**
 *  Retrieve an image at the given @c NSIndexPath
 *
 *  @param indexPath The index path of the desired image, e.g. from @c collectionView:cellForItemAtIndexPath:
 *
 *  @return The image at @c indexPath.
 */
- (MWKImage*)imageAtIndexPath:(NSIndexPath*)indexPath;

@end
