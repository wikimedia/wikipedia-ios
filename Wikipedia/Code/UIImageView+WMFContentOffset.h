@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Collection of methods for applying a "cropping" effect to an image inside a @c UIImageView by modifying its
 *  @c contentsRect.  Modifying the @c contentsRect effectively windows the image set in the receiver, allowing us
 *  to effectively implement our own content modes without subclassing or overriding @c drawRect:.
 *
 *  @note All of these methods take an @c image parameter because the image should be set in a separate call.
 *        Otherwise there could be unexpected scaling/cropping transitions after the image is set.
 */
@interface UIImageView (WMFContentOffset)

/**
 *  Crop the receiver by centering @c rect vertically within the bounds of the image.
 *
 *  @param rect  The frame to center, ignoring width & X origin.
 *  @param image The image to crop.
 */
- (void)wmf_cropContentsByVerticallyCenteringFrame:(CGRect)rect
                               insideBoundsOfImage:(UIImage *)image;

/**
 *  Crop the receiver using a normalized coordinate rectangle relative to a given image.
 *
 *  @param rect  A normalized rect which represents the area to be cropped.
 *  @param image The image whose bounds are used to denormalize @c rect.
 */
- (void)wmf_cropContentsToFrame:(CGRect)rect insideBoundsOfImage:(UIImage *)image;

/**
 *  Crop and shift the receiver's contents by a normalized amount relative to a given image.
 *
 *  @param offset The offset in points (denormalized).
 *  @param image  The image whose bounds will be used to normalize @c offset when calculating
 *                the receiver's new @c contentsRect.
 */
- (void)wmf_setContentOffset:(CGPoint)offset image:(UIImage *)image;

/**
 *  Reset the @c contentsRect of the receiver.
 *
 *  To be used when displaying an entire image as rendered by one of the built-in content modes.
 */
- (void)wmf_resetContentsRect;

/**
 *  Aligns the content to the top of the receiver.
 *
 *  @note The very top of the image is actually cropped off, but in practice it works.
 */
- (void)wmf_topAlignContentsRect:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
