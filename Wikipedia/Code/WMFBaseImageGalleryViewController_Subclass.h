//
//  WMFBaseImageGalleryViewController_Subclass.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseImageGalleryViewController.h"

@class SSBaseDataSource;

@interface WMFBaseImageGalleryViewController ()

/**
 *  The data source used to drive the receiver's collection view.
 *
 *  Can be configured with custom cell classes, etc. at initialization time (@c initWithCollectionViewLayout:).
 */
@property (nonatomic, strong, readwrite) SSBaseDataSource* dataSource;

@end
