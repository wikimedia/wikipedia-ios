#import <WMF/CIDetector+WMFFaceDetection.h>
#import <WMF/CIContext+WMFImageProcessing.h>
#import "UIImage+WMFImageProcessing.h"

NSString *const WMFFaceDetectionErrorDomain = @"org.wikimedia.face-detection-error";

@implementation CIDetector (WMFFaceDetection)

+ (instancetype)wmf_sharedGPUFaceDetector {
    static CIDetector *defaultFaceDetector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultFaceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                 context:[CIContext wmf_sharedGPUContext]
                                                 options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    });
    return defaultFaceDetector;
}

+ (instancetype)wmf_sharedCPUFaceDetector {
    static CIDetector *defaultFaceDetector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultFaceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                 context:[CIContext wmf_sharedCPUContext]
                                                 options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    });
    return defaultFaceDetector;
}

+ (NSDictionary *)wmf_featurelessFaceOptions {
    static NSDictionary *featurelessFaceOptions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        featurelessFaceOptions = @{
            CIDetectorAccuracy: CIDetectorAccuracyLow
        };
    });
    return featurelessFaceOptions;
}

- (void)wmf_detectFeaturelessFacesInImage:(UIImage *)image withFailure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    [self wmf_detectFeaturesInImage:image
                            options:[CIDetector wmf_featurelessFaceOptions]
                            onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                            failure:failure
                            success:success];
}

- (void)wmf_detectFeaturesInImage:(UIImage *)image options:(NSDictionary *)options onQueue:(dispatch_queue_t)queue failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    dispatch_async(queue, ^{
        id features = [self featuresInImage:[image wmf_getOrCreateCIImage] options:options];
        success(features);
    });
}

@end
