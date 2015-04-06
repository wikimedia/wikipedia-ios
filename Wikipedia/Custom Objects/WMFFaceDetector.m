//  Created by Monte Hurd on 12/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFFaceDetector.h"

@interface WMFFaceDetector ()

@property (strong, atomic) CIDetector* detector;
@property (strong, atomic) NSArray* faces;
@property (atomic) NSInteger nextFaceIndex;
@property (atomic, readwrite) CGRect faceBounds;

@end

@implementation WMFFaceDetector

- (instancetype)init {
    self = [super init];
    if (self) {
        self.detector =
            [CIDetector detectorOfType:CIDetectorTypeFace
                               context:nil
                               options:@{
                 CIDetectorAccuracy: CIDetectorAccuracyLow,
                 CIDetectorMinFeatureSize: @(0.15)
             }];
    }
    return self;
}

- (CGRect)detectFace {
    // Optimized for repeated calls (for easy cycle through all faces).
    if (!self.image) {
        return CGRectZero;
    }

    // No need to set faces more than once (for repeated call cycling).
    if (!self.faces) {
        NSAssert(self.image.CIImage, @"Attempted to use a UIImage w/o CIImage backing: Create the UIImage with 'imageWithCIImage' so face detection doesn't have to alloc/init a new CIImage to run detection. See: http://stackoverflow.com/a/15651358/135557");
        self.faces = [self.detector featuresInImage:self.image.CIImage];
    }

    CGRect widestFaceRect = CGRectZero;

    // Index overrun protection.
    if (self.nextFaceIndex >= self.faces.count) {
        return CGRectZero;
    }

    // Get face for nextFaceIndex.
    widestFaceRect = ((CIFaceFeature*)self.faces[self.nextFaceIndex]).bounds;

    if (CGRectIsEmpty(widestFaceRect)) {
        return CGRectZero;
    }

    // Increment so next call will return next face.
    self.nextFaceIndex++;

    // Reset if last face so next call shows first face.
    if (self.nextFaceIndex == self.faces.count) {
        self.nextFaceIndex = 0;
    }

    CGRect faceImageCoords =
        (CGRect){
        {widestFaceRect.origin.x, self.image.size.height - widestFaceRect.origin.y - widestFaceRect.size.height},
        widestFaceRect.size
    };

    return faceImageCoords;
}

- (void)setImage:(UIImage*)image {
    _image             = image;
    self.nextFaceIndex = 0;
    self.faces         = nil;
}

@end
