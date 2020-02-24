@import UIKit;
@class MWKImage;
#import <WMF/WMFBlockDefinitions.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WMFImageFetching)

/**
 *  Sets the image to nil. Cancels any image requests.
 *
 *  It's recommended to call this before setting another image manually via `-[UIImage setImage:]`, but it's not
 *  necessary before another call to `-[UIImage wmf_setImageFromMetadata:options:withBlock:completion:onError:]`
 *  as these will implicitly cancel any pending image reqeusts.
 */
- (void)wmf_reset;

/**
 *  Set the receiver's @c image to the @c imageURL, optionally centering any faces found.
 *  Face detection data will be held in memory.
 *  THIS WILL NOT PERSIST THE RESULTS - IT WILL ONLY HOLD THE RESULTS IN MEMORY
 *
 *  @param imageURL url of the image you want to set.
 *  @param detectFaces Set to YES to detect faces.
 */
- (void)wmf_setImageWithURL:(NSURL *)imageURL detectFaces:(BOOL)detectFaces onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  The URL to fetch, depending on the current values of @c wmf_imageMetadata and @c wmf_imageURL.
 *
 *  @return A URL to the image to display in the receiver, or @c nil if none is set.
 */
@property (nonatomic, strong, nullable, readonly) NSURL *wmf_imageURLToFetch;

/**
*  Use to detect faces if you have already fetched image data by other means.
 
@param image - UIImage to set.
 @param imageURL - url that is only used for task tracking internally and cancelling. Image data is pulled from image, not fetched with imageURL.
*/
- (void)wmf_setImageWithUIImage:(UIImage *)image
        imageURL:(NSURL *)imageURL
        detectFaces:(BOOL)detectFaces
        onGPU:(BOOL)onGPU
        failure:(WMFErrorHandler)failure
             success:(WMFSuccessHandler)success;

@end

NS_ASSUME_NONNULL_END
