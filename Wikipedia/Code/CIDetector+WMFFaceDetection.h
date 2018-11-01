@import CoreImage;
#import <WMF/WMFBlockDefinitions.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFFaceDetectionErrorDomain;

typedef NS_ENUM(NSInteger, WMFFaceDectionError) {
    WMFFaceDectionErrorUnknown = 0,
    WMFFaceDectionErrorAppInBackground = 1 //face detection on GPU not allowed in the background
};

@interface CIDetector (WMFFaceDetection)

/**
 * Singleton `CIDetector` configured to detect faces.
 */
+ (instancetype)wmf_sharedGPUFaceDetector;
+ (instancetype)wmf_sharedCPUFaceDetector;

/**
 * Asynchronously detect faces in `image`, without doing extra processing for smiles or eyes.
 */
- (NSOperation *)wmf_detectFeaturelessFacesInImage:(UIImage *)image withFailure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success;

@end

NS_ASSUME_NONNULL_END
