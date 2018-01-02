#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
#import <WMF/WMFBlockDefinitions.h>
@class MWKImage;
@class WMFImageController;
@class WMFFaceDetectionCache;

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
 *  The cancellation token associated with the currently loading image
 *
 */
@property (nonatomic, copy, nullable, setter=wmf_setImageTokenToCancel:) NSString *wmf_imageTokenToCancel;

/**
 *  The metadata associated with the receiver.
 *
 *  This is preferred over @c wmf_imageURL since it allows for normalized face detection data to be read from and written
 *  to disk.
 *
 *  @see wmf_imageURL
 */
@property (nonatomic, strong, nullable, setter=wmf_setImageMetadata:) MWKImage *wmf_imageMetadata;

/**
 *  The image controller used to fetch image data.
 *
 *  Used to cancel the previous fetch executed by the receiver. Defaults to @c [WMFImageController sharedInstance].
 */
@property (nonatomic, weak, nullable, setter=wmf_setImageController:) WMFImageController *wmf_imageController;

/**
 *  Fetch the receiver's @c wmf_imageURLToFetch
 *
 *  @param detectFaces Whether or not face detection & centering is desired.
 *  @param success Invoked after the image has been successfully set and animated into view.
 *
 */
- (void)wmf_fetchImageDetectFaces:(BOOL)detectFaces onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  Cancels any ongoing fetch for the receiver's current image, using its internal @c WMFImageController.
 *
 *  @see wmf_imageURLToFetch
 */
- (void)wmf_cancelImageDownload;

@end

NS_ASSUME_NONNULL_END
