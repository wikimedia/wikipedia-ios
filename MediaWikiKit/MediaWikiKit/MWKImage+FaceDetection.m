//
//  MWKImage+FaceDetection.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/18/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImage+FaceDetection.h"
#import "Wikipedia-Swift.h"
#import <PromiseKit/AnyPromise.h>
#import "CIDetector+WMFFaceDetection.h"
#import "UIImage+WMFNormalization.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKImage (FaceDetection)

- (void)setNormalizedFaceBoundsFromFeatures:(NSArray*)features inImage:(UIImage*)image {
    self.allNormalizedFaceBounds = [features bk_map:^NSValue*(CIFeature* feature) {
        return [NSValue valueWithCGRect:[image wmf_normalizeAndConvertCGCoordinateRect:feature.bounds]];
    }] ? : @[];
    NSParameterAssert(self.didDetectFaces);
}

- (AnyPromise*)setFaceBoundsFromFeaturesInImage:(UIImage*)image {
    return [[CIDetector wmf_sharedLowAccuracyBackgroundFaceDetector] wmf_detectFeaturelessFacesInImage:image]
           .then(^(NSArray* features) {
        [self setNormalizedFaceBoundsFromFeatures:features inImage:image];
        return self;
    });
}

@end

NS_ASSUME_NONNULL_END
