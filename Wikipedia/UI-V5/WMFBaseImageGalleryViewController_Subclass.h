//
//  WMFBaseImageGalleryViewController_Subclass.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseImageGalleryViewController.h"

@interface WMFBaseImageGalleryViewController ()

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout NS_DESIGNATED_INITIALIZER;

/**
 *  The data source used to drive the receiver's collection view.
 *
 *  Can be configured with custom cell classes, etc. at initialization time (@c initWithCollectionViewLayout:).
 */
@property (nonatomic, strong, readonly) WMFImageGalleryDataSource* dataSource;

@end
