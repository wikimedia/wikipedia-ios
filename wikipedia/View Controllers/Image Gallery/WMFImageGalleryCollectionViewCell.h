//
//  MWKImageGalleryCollectionViewCell.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMFImageGalleryDetailOverlayView;

@interface WMFImageGalleryCollectionViewCell : UICollectionViewCell
@property (nonatomic) UIImage *image;
@property (nonatomic, weak, readonly) WMFImageGalleryDetailOverlayView *detailOverlayView;

@end
