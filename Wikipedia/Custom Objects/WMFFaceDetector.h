
#import <UIKit/UIKit.h>

@interface WMFFaceDetector : NSObject

@property (nonatomic, strong) CIImage* image;

/**
 *  Set the image property with UIImage
 *  Useful if you didn't have a CIImage before hand
 *  Will attempt to use image.CIImage first, then fallback to UIImagePNGRepresentation()
 *
 *  @param image the image to use
 */
- (void)setImageWithUIImage:(UIImage*)image;

/**
 *  Set the image property with NSData
 *  Useful if you didn't have a CIImage before hand
 *
 *  @param data to create the image from
 */
- (void)setImageWithData:(NSData*)data;

/**
 *  Detect faces synchronously
 */
- (void)detectFaces;

/**
 *  Detect faces async
 *
 *  @param completion fired when face detection is completed
 */
- (void)detectFacesWithCompletionBlock:(dispatch_block_t)completion;

/**
 *  All faces
 *
 *  @return An array of CIFaceFeature
 */
- (NSArray*)allFaces;

/**
 *  Get an array of the bounds of all the faces. Each bounds will be normalized
 *  to the image size so values are between 0.0 and 1.0. This so it can be used
 *  with any size thumbnail of the image. Finally all bounds are encoded as
 *  NSStrings.
 *
 *  @return The array of NSStrings representing the normalized bounds of each face
 */
- (NSArray*)allFaceBoundsAsStringsNormalizedToUnitRect;

/**
 *  Normaize a rect against the bounds of the image.
 *
 *  @param frame The frame to normalize
 *
 *  @return The normalized frame
 */
- (CGRect)rectNormailzedToUnitRect:(CGRect)frame;

@end
