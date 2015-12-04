//
//  WMFModalArticleImageGalleryDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleImageGalleryDataSource.h"
#import "WMFModalImageGalleryDataSource.h"

/**
 *  Data source for the modal article image gallery.
 *
 *  Extension of @c WMFArticleImageGalleryDataSource which also fetches metadata for its images.
 */
@interface WMFModalArticleImageGalleryDataSource : WMFArticleImageGalleryDataSource
    <WMFModalImageGalleryDataSource>

@end
