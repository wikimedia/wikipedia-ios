//
//  NYTPhoto.h
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/10/15.
//  Copyright (c) 2015 NYTimes. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The model for photos displayed in an `NYTPhotosViewController`.
 */
@protocol NYTPhoto <NSObject>

/**
 *  The image to display.
 *
 *  This property is used if and only if `-imageData` returns `nil`. Note, however, that returning `UIImage`s from this property whenever possible will result in better performance. See `-imageData`'s documentation for discussion.
 */
@property (nonatomic, readonly, nullable) UIImage *image;

/**
 *  The image data to display.
 *  
 *  This property's value, if non-`nil`, is preferred over `-image`. This allows clients to provide image data for FLAnimatedImage when the library is compiled with `ANIMATED_GIF_SUPPORT` defined.
 *
 *  Note that if you're working with a non-animated image, using a native `UIImage` will provide better performance. Therefore, it is recommended to return `nil` from this property unless this photo is an animated GIF.
 */
@property (nonatomic, readonly, nullable) NSData *imageData;

/**
 *  The UTType of the image data
 */
@property (nonatomic, readonly, nullable) NSString *imageDataUTType;

/**
 *  A placeholder image for display while the image is loading.
 *
 *  This property is used if and only if `-imageData` returns `nil`.
 */
@property (nonatomic, readonly, nullable) UIImage *placeholderImage;

/**
 *  An attributed string for display as the title of the caption.
 */
@property (nonatomic, readonly, nullable) NSAttributedString *attributedCaptionTitle;

/**
 *  An attributed string for display as the summary of the caption.
 */
@property (nonatomic, readonly, nullable) NSAttributedString *attributedCaptionSummary;

/**
 *  An attributed string for display as the credit of the caption.
 */
@property (nonatomic, readonly, nullable) NSAttributedString *attributedCaptionCredit;

@end

NS_ASSUME_NONNULL_END
