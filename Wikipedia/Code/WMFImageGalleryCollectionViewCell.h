//
//  MWKImageGalleryCollectionViewCell.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SSDataSources/SSBaseCollectionCell.h>

@class WMFImageGalleryDetailOverlayView;

@interface WMFImageGalleryCollectionViewCell : SSBaseCollectionCell

/**
 * Size the image should be displayed, used to show low-res images at high-res sizes for smoother transitions.
 * @discussion This property defaults to <code>CGSizeZero</code>, in which case the image's intrinsic size will be used.
 */
@property (nonatomic) CGSize imageSize;

/**
 * Get and set the currently displayed image.
 * @note This setter takes precedence over @c imageView.image since other cell elements need to be laid out as a result
 *       of the image changing.
 */
@property (nonatomic, strong) UIImage* image;

/// The subview which displays additional information about the image.
@property (nonatomic, weak, readonly) WMFImageGalleryDetailOverlayView* detailOverlayView;

@property (nonatomic, getter = isLoading) BOOL loading;

- (void)startLoadingAfterDelay:(NSTimeInterval)seconds;

/**
 *  Do not set the image here directly - this is exposed only
 *  for animation purposes
 */
@property (nonatomic, weak, readonly) UIImageView* imageView;

@end
