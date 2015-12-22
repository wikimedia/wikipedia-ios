//
//  CIDetector+WMFFaceDetection.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "CIDetector+WMFFaceDetection.h"
#import "Wikipedia-Swift.h"

#import <BlocksKit/BlocksKit.h>
#import "CIContext+WMFImageProcessing.h"
#import "UIImage+WMFImageProcessing.h"

@implementation CIDetector (WMFFaceDetection)

+ (instancetype)wmf_sharedBackgroundFaceDetector {
    static CIDetector* defaultFaceDetector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultFaceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                 context:[CIContext wmf_sharedBackgroundContext]
                                                 options:nil];
    });
    return defaultFaceDetector;
}

+ (NSDictionary*)wmf_featurelessFaceOptions {
    static NSDictionary* featurelessFaceOptions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        featurelessFaceOptions = @{
//            CIDetectorEyeBlink: @NO,
//            CIDetectorSmile: @NO
        };
    });
    return featurelessFaceOptions;
}

- (AnyPromise*)wmf_detectFeaturelessFacesInImage:(UIImage*)image {
    return [self wmf_detectFeaturesInImage:image
                                   options:[CIDetector wmf_featurelessFaceOptions]
                                        on:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (AnyPromise*)wmf_detectFeaturesInImage:(UIImage*)image options:(NSDictionary*)options on:(dispatch_queue_t)queue {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_async(queue, ^{
            resolve([self featuresInImage:[image wmf_getOrCreateCIImage] options:options]);
        });
    }];
}

@end
