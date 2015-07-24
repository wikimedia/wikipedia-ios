
#import <UIKit/UIKit.h>

@interface WMFFaceDetector : NSObject

@property (nonatomic, strong, readonly) CIImage* image;

/**
 * The `CIFeature` objects representing faces detected by the receiver.
 *
 * This will be `nil` before detection is run, and a non-empty array afterwards.
 */
@property (nonatomic, copy, readonly) NSArray* faces;

- (instancetype)initWithCIImage:(CIImage*)image NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithUIImage:(UIImage*)image;

- (instancetype)initWithImageData:(NSData*)data;

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
 *  Get an array of the bounds of all the faces. Each bounds will be normalized
 *  to the image size so values are between 0.0 and 1.0. This so it can be used
 *  with any size thumbnail of the image. Finally all bounds are encoded as
 *  NSStrings.
 *
 *  @return The array of NSStrings representing the normalized bounds of each face
 */
- (NSArray*)allFaceBoundsAsStringsNormalizedToUnitRect;

/**
 *  Normalize a rect against the bounds of the image.
 *
 *  @param frame The frame to normalize
 *
 *  @return The normalized frame
 */
- (CGRect)rectNormalizedToUnitRect:(CGRect)frame;

@end
