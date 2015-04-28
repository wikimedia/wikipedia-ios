//  Created by Monte Hurd on 12/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFFaceDetector.h"
#import <BlocksKit/BlocksKit.h>
#import "WMFGeometry.h"

@interface WMFFaceDetector ()

@property (strong, atomic) CIDetector* detector;
@property (strong, atomic) NSArray* faces;
@property (assign, atomic) BOOL faceDetectionHasRan;

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

- (void)setImageWithUIImage:(UIImage*)image {
    if (image.CIImage) {
        self.image = image.CIImage;
    } else {
        [self setImageWithData:UIImagePNGRepresentation(image)];
    }
}

- (void)setImageWithData:(NSData*)data {
    CIImage* ciImage = [[CIImage alloc] initWithData:data];
    self.image = ciImage;
}

- (void)detectFaces {
    if (!self.image) {
        return;
    }

    if (!self.faceDetectionHasRan) {
        self.faces               = [self.detector featuresInImage:self.image];
        self.faceDetectionHasRan = YES;
    }
}

- (void)detectFacesWithCompletionBlock:(dispatch_block_t)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self detectFaces];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)setImage:(CIImage*)image {
    _image                   = image;
    self.faces               = nil;
    self.faceDetectionHasRan = NO;
}

- (NSArray*)allFaces {
    return self.faces;
}

- (NSArray*)allFaceBoundsAsStringsNormalizedToUnitRect {
    return [self.faces bk_map:^id (CIFaceFeature* obj) {
        CGRect bounds = [obj bounds];
        CGRect normalized = [self rectNormailzedToUnitRect:bounds];
        return NSStringFromCGRect(normalized);
    }];
}

- (CGRect)rectNormailzedToUnitRect:(CGRect)frame {
    return WMFUnitRectWithReferenceRect(frame, [self.image extent]);
}

@end
