
#import "UIImageView+WMFImageFetching.h"

@class MWKImage;
@class WMFImageController;
@class WMFFaceDetectionCache;

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WMFAssociatedObjects)

/**
 *   The cache used to hold any detected faces
 *
 */
+ (WMFFaceDetectionCache*)faceDetectionCache;

/**
 *   The image URL associated with the receiver.
 *
 */
@property (nonatomic, strong, nullable, setter = wmf_setImageURL:) NSURL* wmf_imageURL;

/**
 *  The metadata associated with the receiver.
 *
 *  Used to ensure that images set on the receiver aren't associated with a URL for another metadata entity.
 *
 */
@property (nonatomic, strong, nullable, setter = wmf_setImageMetadata:) MWKImage* wmf_imageMetadata;

/**
 *  The image controller used to fetch image data.
 *
 *  Used to cancel the previous fetch executed by the receiver. Default is [WMFImageController sharedInstance].
 */
@property (nonatomic, weak, nullable, setter = wmf_setImageController:) WMFImageController* wmf_imageController;

@end

NS_ASSUME_NONNULL_END
