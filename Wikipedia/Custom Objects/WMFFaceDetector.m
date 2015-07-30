//  Created by Monte Hurd on 12/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFFaceDetector.h"
#import <BlocksKit/BlocksKit.h>
#import "WMFGeometry.h"

@interface WMFFaceDetector ()
@property (strong, nonatomic) CIDetector* detector;
@property (strong, nonatomic) CIImage* image;
@property (readwrite, copy, nonatomic) NSArray* faces;
@end

@implementation WMFFaceDetector

+ (CIDetector*)sharedDetector {
    static CIDetector* sharedDetector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                            context:nil
                                            options:@{
                              CIDetectorAccuracy: CIDetectorAccuracyLow,
                              CIDetectorMinFeatureSize: @(0.15)
                          }];
    });
    return sharedDetector;
}

- (instancetype)init {
    return [self initWithCIImage:nil];
}

- (instancetype)initWithImageData:(NSData*)data {
    NSParameterAssert(data.length);
    return [self initWithCIImage:[[CIImage alloc] initWithData:data]];
}

- (instancetype)initWithUIImage:(UIImage*)image {
    return [self initWithCIImage:image.CIImage ? : [[CIImage alloc] initWithCGImage:image.CGImage]];
}

- (instancetype)initWithCIImage:(CIImage*)image {
    NSParameterAssert(image);
    if (!image) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.detector = [[self class] sharedDetector];
        self.image    = image;
    }
    return self;
}

- (void)detectFaces {
    if (!self.faces) {
        self.faces = [self.detector featuresInImage:self.image];
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

- (NSArray*)allFaceBoundsAsStringsNormalizedToUnitRect {
    return [[self.faces bk_reject:^BOOL (CIFeature* feature) {
        return CGRectIsEmpty(feature.bounds);
    }] bk_map:^id (CIFaceFeature* feature) {
        CGRect uiKitBounds = WMFUIKitRectFromCoreImageRectInReferenceRect(feature.bounds, self.image.extent);
        CGRect normalized = [self rectNormalizedToUnitRect:uiKitBounds];
        return NSStringFromCGRect(normalized);
    }];
}

- (CGRect)rectNormalizedToUnitRect:(CGRect)frame {
    return WMFUnitRectWithReferenceRect(frame, [self.image extent]);
}

@end
