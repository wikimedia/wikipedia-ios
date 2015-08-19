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

/**
 *  Applys a bitmask of @c WMFImageOptions to an animation flag, returning the result.
 *
 *  @param options  The options to apply.
 *  @param animated Whether or not the transition should be animated, before applying user options.
 *
 *  @return @c NO if @c WMFImageOptionNeverAnimate is set, @c YES if @c WMFImageOptionAlwaysAnimate is set, or the
 *          value originally passed in the @c animated parameter.
 */
static inline BOOL WMFApplyImageOptionsToAnimationFlag(WMFImageOptions options, BOOL animated) {
    return !(options & WMFImageOptionNeverAnimate)
           && ((options & WMFImageOptionAlwaysAnimate) || animated);
}

extern BOOL WMFShouldDetectFacesForMetadataWithOptions(MWKImage* imageMetadata, WMFImageOptions options);

@interface UIImageView (WMFAssociatedObjects)

/**
 *  The metadata associated with the receiver.
 *
 *   Used to ensure that images set on the receiver aren't associated with a URL for another metadata entity.
 *
 *   @warning Do not set directly, instead use @c -wmf_setMetadata:controller:.
 */
@property (nonatomic, strong, nullable) MWKImage* wmf_imageMetadata;

/**
 *  The image controller used to fetch image data.
 *
 *  Used to cancel the previous fetch executed by the receiver.
 *
 *  @warning Do not set direclty, instead use @c wmf_setMetadata:controller:
 */
@property (nonatomic, weak, nullable) WMFImageController* wmf_imageController;

- (void)wmf_setMetadata:(MWKImage* __nullable)imageMetadata controller:(WMFImageController* __nullable)imageController;

@end

@interface UIImageView (MWKImageInternal)

/// @see wmf_setImageFromMetadata:options:withBlock:completion:onError:
- (void)wmf_setImageFromMetadata:(MWKImage*)imageMetadata
                         options:(WMFImageOptions)options
                       withBlock:(WMFSetImageBlock __nullable)inputSetImageBlock
                      completion:(void (^ __nullable)(BOOL))completion
                         onError:(void (^ __nullable)(NSError*))failure
                 usingController:(WMFImageController*)controller;

/// @see wmf_setCachedImageForMetadata:options:setImageBlock:completion:
- (BOOL)wmf_setCachedImageForMetadata:(MWKImage*)imageMetadata
                              options:(WMFImageOptions)options
                        setImageBlock:(WMFSetImageBlock __nullable)setImageBlock
                           completion:(void (^ __nullable)(BOOL))completion
                      usingController:(WMFImageController*)controller;

/**
 *  Sets the receiver's <code>image</code><b> if it is still associated with @c imageMetadata</b>.
 *
 *  This is the final method invoked by @c wmf_setImageFromMetadata or @c wmf_setCachedIamgeForMetadata. When called,
 *  it executes business logic to determine whether or not to transition to the new image, as well as invoking
 *  @c setImageBlock and @c completion at the appropriate points.
 *
 *  @param image         The image to set.
 *  @param imageMetadata Metadata associated with @c image. Used for face centering & to prevent the image from being
 *                       set it the receiver's associated image metadata has changed.
 *  @param options       Options used to determine how the image is set.
 *  @param setImageBlock Block used to set the image
 *  @param completion    Block to call after the image is set.
 *  @param animated      Whether or not the new image should be set with an animation (depending on @c options).
 *
 *  @see -wmf_setImageForMetadata:options:withBlock:completion:onError:
 */
- (void)wmf_setImage:(UIImage*)image
         forMetadata:(MWKImage*)imageMetadata
             options:(WMFImageOptions)options
           withBlock:(WMFSetImageBlock __nullable)setImageBlock
          completion:(void (^ __nullable)(BOOL))completion
            animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
