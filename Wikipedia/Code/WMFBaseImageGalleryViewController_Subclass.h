//
//  WMFBaseImageGalleryViewController_Subclass.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseImageGalleryViewController.h"
#import "WMFImageGalleryDataSource.h"

@class SSBaseDataSource;

NS_ASSUME_NONNULL_BEGIN

@interface WMFBaseImageGalleryViewController ()

/**
 *  The data source used to drive the receiver's collection view.
 *
 *  This also resets the @c currentPage property in order to maintain RTL compliance (set to last item in legacy RTL
 *  environments).
 *
 *  Subclasses should <i>preferrably</i> set this property <b>at initialization time</b>. When set, the receiver's
 *  @c currentPage as needed for RTL compliance and, if the view is loaded, the data source is connected to the
 *  collection view.
 */
@property(nonatomic, strong, nullable, readwrite) SSBaseDataSource<WMFImageGalleryDataSource> *dataSource;

@end

NS_ASSUME_NONNULL_END
