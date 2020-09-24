#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
#import <WMF/WMFBlockDefinitions.h>
@class MWKImage;
@class WMFPermanentCacheController;
@class WMFFaceDetectionCache;
@class FLAnimatedImage;

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WMFImageFetchingInternal)

/**
 *   The cache used to hold any detected faces
 *
 */
+ (WMFFaceDetectionCache *)faceDetectionCache;

/**
 *  The image URL associated with the receiver.
 *
 *  Used to ensure that images set on the receiver aren't associated with a URL for another metadata entity.
 */
@property (nonatomic, strong, nullable, setter=wmf_setImageURL:) NSURL *wmf_imageURL;

/**
 *  The image URL associated with the currently loading image
 *
 */
@property (nonatomic, strong, nullable, setter=wmf_setImageURLToCancel:) NSURL *wmf_imageURLToCancel;

/**
 *  The image URL associated with the current face detection
 *
 */
@property (nonatomic, strong, nullable, setter=wmf_setFaceDetectionImageURLToCancel:) NSURL *wmf_faceDetectionImageURLToCancel;

/**
 *  The cancellation token associated with the currently loading image
 *
 */
@property (nonatomic, copy, nullable, setter=wmf_setImageTokenToCancel:) NSString *wmf_imageTokenToCancel;

/**
 *  Fetch the receiver's @c wmf_imageURLToFetch
 *
 *  @param detectFaces Whether or not face detection & centering is desired.
 *  @param success Invoked after the image has been successfully set and animated into view.
 *
 */
- (void)wmf_fetchImageDetectFaces:(BOOL)detectFaces onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  Cancels any ongoing fetch for the receiver's current image, using its internal @c WMFPermanentCacheController.
 *
 *  @see wmf_imageURLToFetch
 */
- (void)wmf_cancelImageDownload;

@end

NS_ASSUME_NONNULL_END
