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

- (NSOperation *)wmf_detectFeaturelessFacesInImage:(UIImage *)image withFailure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    return [self wmf_detectFeaturesInImage:image
                            options:[CIDetector wmf_featurelessFaceOptions]
                            failure:failure
                            success:success];
}

- (NSOperation *)wmf_detectFeaturesInImage:(UIImage *)image options:(NSDictionary *)options failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    NSOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        id features = [self featuresInImage:[image wmf_getOrCreateCIImage] options:options];
        success(features);
    }];
    return blockOperation;
}

@end
