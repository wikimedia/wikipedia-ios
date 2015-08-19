//
//  UIImageView+MWKImage.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWKImage;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, WMFImageOptions) {
    /**
     *  Run face detection (if needed) and center the face inside the receiver.
     */
    WMFImageOptionCenterFace = 1 << 0,

        /**
         *  Animate regardless of whether or not the image was retrieved from memory.
         *
         *  @warning Do not set this flag in combination with `WMFImageOptionNeverAnimate`.
         *
         *  @see WMFImageOptionCrossDissolve
         */
        WMFImageOptionAlwaysAnimate = 1 << 2,

        /**
         *  Do not animate when setting the new image.
         *
         *  @warning Do not set this flag in combination with `WMFImageOptionAlwaysAnimate`.
         *
         *  @see WMFImageOptionCrossDissolve
         */
        WMFImageOptionNeverAnimate = 1 << 3,
};

/**
 *  The type of block which is invoked to set an image on an `UIImageView`
 *
 *  @warning Use the provided `imageView` argument to the block instead of referencing the `UIImageView` directly. This
 *           will prevent any unintentional retain cycles.
 *
 *  @param imageView     The original receiver of the call to `wmf_setImageFromMetadata:options:withBlock:completion:onError:`
 *  @param image         The image to set.
 *  @param imageMetadata The metadata used to retrieve `image`.
 */
typedef void (^ WMFSetImageBlock)(UIImageView* imageView, UIImage* image, MWKImage* imageMetadata);

@interface UIImageView (MWKImage)

/**
 *  Reset the receiver's image metadata.
 *
 *  It's recommended to call this before setting another image manually via `-[UIImage setImage:]`, but it's not
 *  necessary before another call to `-[UIImage wmf_setImageFromMetadata:options:withBlock:completion:onError:]`.
 */
- (void)wmf_resetImageMetadata;

/**
 *  Set the receiver's @c image to the @c sourceURL of the given @c imageMetadata, centering any faces found.
 *
 *  @param imageMetadata Metadata with the `sourceURL` of the image you want to set.
 *
 *  @see wmf_setImageFromMetadata:options:withBlock:completion:onError:
 */
- (void)wmf_setImageWithFaceDetectionFromMetadata:(MWKImage*)imageMetadata;

/**
 *  Set the receiver's image to the source URL of the given `imageMetadata`.
 *
 *  Will set the image synchronously if possible, but failing that, fetches the image from network or disk and then
 *  (if specified in @c options) detects and centers faces (if found). This method is both idempotent and cancelling in
 *  that setting the same @c imageMetadata repeatedly is a no-op after the first call, and setting a different
 *  @c imageMetadata or @c nil will prevent the previous metadata's image from being set.
 *
 *  @param imageMetadata Metadata with the `sourceURL` of the image you want to set.
 *  @param options       Control how the image is set by specifying a bitmask of `WMFImageOptions`.
 *  @param setImageBlock Called when the image is going to be set on the receiver. Default simply sets the image on the receiver.
 *  @param completion    Called after the image has been set (i.e. after any fetching, processing, and/or animations).
 *  @param failure       Called if the image could not be retrieved from the network.
 */
- (void)wmf_setImageFromMetadata:(MWKImage*)imageMetadata
                         options:(WMFImageOptions)options
                       withBlock:(WMFSetImageBlock __nullable)setImageBlock
                      completion:(dispatch_block_t __nullable)completion
                         onError:(void (^ __nullable )(NSError*))failure;

/**
 *  Attempts to retrieve a cached image for @c imageMetadata from memory and set it synchronously.
 *
 *  @param imageMetadata Metadata to retrieve an image for.
 *  @param options       Options determining how to set the image.
 *  @param setImageBlock Block which should be called to set the image.
 *  @param completion    Block to call after the image was set.
 *
 *  @return @c YES if a cached image was set, or @c NO if the image wasn't in memory or face detection needed to
 *          be performed.
 */
- (BOOL)wmf_setCachedImageForMetadata:(MWKImage*)imageMetadata
                              options:(WMFImageOptions)options
                        setImageBlock:(WMFSetImageBlock __nullable)setImageBlock
                           completion:(dispatch_block_t __nullable)completion;

@end

NS_ASSUME_NONNULL_END
