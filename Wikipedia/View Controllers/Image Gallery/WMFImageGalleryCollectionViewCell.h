//
//  MWKImageGalleryCollectionViewCell.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMFImageGalleryDetailOverlayView;
@class WMFGradientView;

@interface WMFImageGalleryCollectionViewCell : UICollectionViewCell

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
@property (nonatomic) UIImage* image;

/// The subview which displays additional information about the image.
@property (nonatomic, weak, readonly) WMFImageGalleryDetailOverlayView* detailOverlayView;

/// Set @c alpha for the gradient & detail overlay views. This is preferred to hiding & showing them.
- (void)setDetailViewAlpha:(float)alpha;

@end
