
#import "WMFFaceDetectionCache.h"
#import "Wikipedia-Swift.h"
#import "CIDetector+WMFFaceDetection.h"
#import "UIImage+WMFNormalization.h"
#import "MWKImage.h"

@interface WMFFaceDetectionCache ()

@property (nonatomic, strong) NSCache* faceDetectionBoundsKeyedByURL;

@end


@implementation WMFFaceDetectionCache

- (instancetype)init {
    self = [super init];
    if (self) {
        self.faceDetectionBoundsKeyedByURL = [[NSCache alloc] init];
    }
    return self;
}

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL*)url {
    return ([self faceDetectionBoundsForURL:url] == nil);
}

- (BOOL)imageRequiresFaceDetection:(MWKImage*)imageMetadata {
    return ![imageMetadata didDetectFaces];
}

- (NSValue*)faceBoundsForURL:(NSURL*)url {
    return [[self faceDetectionBoundsForURL:url] firstObject];
}

- (NSValue*)faceBoundsForImageMetadata:(MWKImage*)imageMetadata {
    return [imageMetadata.allNormalizedFaceBounds firstObject];
}

- (AnyPromise*)detectFaceBoundsInImage:(UIImage*)image URL:(NSURL*)url {
    NSArray* savedBounds = [self faceDetectionBoundsForURL:url];
    if (savedBounds) {
        return [AnyPromise promiseWithValue:[savedBounds firstObject]];
    } else {
        return [self getFaceBoundsInImage:image]
               .then(^(NSArray* faceBounds) {
            [self cacheFaceDetectionBounds:faceBounds forURL:url];
            return [faceBounds firstObject];
        });
    }
}

- (AnyPromise*)detectFaceBoundsInImage:(UIImage*)image imageMetadata:(MWKImage*)imageMetadata {
    NSArray* savedBounds = imageMetadata.allNormalizedFaceBounds;
    if (savedBounds) {
        return [AnyPromise promiseWithValue:[savedBounds firstObject]];
    } else {
        return [self getFaceBoundsInImage:image]
               .then(^(NSArray* faceBounds) {
            imageMetadata.allNormalizedFaceBounds = faceBounds;
            [imageMetadata save];
            return [faceBounds firstObject];
        });
    }
}

- (AnyPromise*)getFaceBoundsInImage:(UIImage*)image {
    return [[CIDetector wmf_sharedBackgroundFaceDetector] wmf_detectFeaturelessFacesInImage:image]
           .then(^(NSArray* features) {
        NSArray<NSValue*>* faceBounds = [image wmf_normalizeAndConvertBoundsFromCIFeatures:features];
        return faceBounds;
    });
}

#pragma mark - Cache methods

- (void)cacheFaceDetectionBounds:(NSArray*)bounds forURL:(NSURL*)url {
    NSParameterAssert(url);
    if (!url) {
        return;
    }
    if (!bounds) {
        bounds = @[];
    }

    [self.faceDetectionBoundsKeyedByURL setObject:bounds forKey:url];
}

- (NSArray*)faceDetectionBoundsForURL:(NSURL*)url {
    return [self.faceDetectionBoundsKeyedByURL objectForKey:url];
}

- (void)clearCache {
    [self.faceDetectionBoundsKeyedByURL removeAllObjects];
}

@end
