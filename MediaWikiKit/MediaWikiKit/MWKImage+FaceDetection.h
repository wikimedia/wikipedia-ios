//
//  MWKImage+FaceDetection.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/18/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImage.h"

@class AnyPromise;

@interface MWKImage (FaceDetection)

- (void)setNormalizedFaceBoundsFromFeatures:(NSArray*)features inImage:(UIImage*)image;

- (AnyPromise*)setFaceBoundsFromFeaturesInImage:(UIImage*)image;

@end
