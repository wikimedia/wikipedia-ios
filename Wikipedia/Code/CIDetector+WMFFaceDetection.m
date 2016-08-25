#import "CIDetector+WMFFaceDetection.h"
#import "CIContext+WMFImageProcessing.h"
#import "UIImage+WMFImageProcessing.h"

NSString *const WMFFaceDetectionErrorDomain = @"org.wikimedia.face-detection-error";

@implementation CIDetector (WMFFaceDetection)

+ (instancetype)wmf_sharedFaceDetector {
    static CIDetector *defaultFaceDetector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultFaceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                 context:[CIContext wmf_sharedContext]
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

- (void)wmf_detectFeaturelessFacesInImage:(UIImage *)image onGPU:(BOOL)onGPU withFailure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    [self wmf_detectFeaturesInImage:image
                            options:[CIDetector wmf_featurelessFaceOptions]
                              onGPU:onGPU
                            onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                            failure:failure
                            success:success];
}

- (void)wmf_detectFeaturesInImage:(UIImage *)image options:(NSDictionary *)options onGPU:(BOOL)onGPU onQueue:(dispatch_queue_t)queue failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    dispatch_async(queue, ^{
        if (onGPU) {
            id features = [self featuresInImage:[image wmf_getOrCreateCIImage] options:options];
            success(features);
        } else {
            //TODO: use software renderer here
            failure([NSError errorWithDomain:WMFFaceDetectionErrorDomain code:WMFFaceDectionErrorAppInBackground userInfo:nil]);
        }
    });
}

@end
