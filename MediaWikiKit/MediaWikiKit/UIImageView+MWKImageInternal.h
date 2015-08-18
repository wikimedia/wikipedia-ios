//
//  UIImageView+MWKImageInternal.h
//
//
//  Created by Brian Gerstle on 8/18/15.
//
//

#import "UIImageView+MWKImage.h"

@class MWKImage;
@class WMFImageController;

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WMFAssociatedMWKImage)

@property (nonatomic, strong, nullable) MWKImage* wmf_imageMetadata;

@end

@interface UIImageView (MWKImageInternal)

/// @see wmf_setImageFromMetadata:options:withBlock:completion:onError:
- (void)wmf_setImageFromMetadata:(MWKImage* __nullable)imageMetadata
                         options:(WMFImageOptions)options
                       withBlock:(WMFSetImageBlock __nullable)inputSetImageBlock
                      completion:(dispatch_block_t __nullable)completion
                         onError:(void (^ __nullable)(NSError*))failure
                 usingController:(WMFImageController*)controller;

/// @see wmf_setCachedImageForMetadata:options:setImageBlock:completion:
- (BOOL)wmf_setCachedImageForMetadata:(MWKImage*)imageMetadata
                              options:(WMFImageOptions)options
                        setImageBlock:(WMFSetImageBlock __nullable)setImageBlock
                           completion:(dispatch_block_t __nullable)completion
                      usingController:(WMFImageController*)controller;

/**
 *  Sets the receiver's `image` if it is still associated with `imageMetadata`.
 *
 *  Executes business logic to determine whether or not to transition to the new image, as well as invoking
 *  `setImageBlock` and `completion` at the appropriate points.
 *
 *  @param image         The image to set.
 *  @param imageMetadata Metadata associated with `image`. Used for face centering & to prevent the image from being
 *                       set it the receiver's associated image metadata has changed.
 *  @param options       Options used to determine how the image is set.
 *  @param setImageBlock Block used to set the image
 *  @param completion    Block to call after the image is set.
 *  @param animated      Whether or not the new image should be set with an animation (depending on `options`).
 *
 *  @see -wmf_setImageForMetadata:options:withBlock:completion:onError:
 */
- (void)wmf_setImage:(UIImage*)image
         forMetadata:(MWKImage*)imageMetadata
             options:(WMFImageOptions)options
           withBlock:(WMFSetImageBlock __nullable)setImageBlock
          completion:(dispatch_block_t __nullable)completion
            animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
