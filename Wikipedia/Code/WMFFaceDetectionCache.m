#import "WMFFaceDetectionCache.h"
#import "Wikipedia-Swift.h"
#import "CIDetector+WMFFaceDetection.h"
#import "UIImage+WMFNormalization.h"
#import "MWKImage.h"

@interface WMFFaceDetectionCache ()

@property(nonatomic, strong) NSCache *faceDetectionBoundsKeyedByURL;

@end

@implementation WMFFaceDetectionCache

- (instancetype)init {
  self = [super init];
  if (self) {
    self.faceDetectionBoundsKeyedByURL = [[NSCache alloc] init];
  }
  return self;
}

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL *)url {
  return ([self faceDetectionBoundsForURL:url] == nil);
}

- (BOOL)imageRequiresFaceDetection:(MWKImage *)imageMetadata {
  return ![imageMetadata didDetectFaces];
}

- (NSValue *)faceBoundsForURL:(NSURL *)url {
  return [[self faceDetectionBoundsForURL:url] firstObject];
}

- (NSValue *)faceBoundsForImageMetadata:(MWKImage *)imageMetadata {
  return [imageMetadata.allNormalizedFaceBounds firstObject];
}

- (void)detectFaceBoundsInImage:(UIImage *)image URL:(NSURL *)url failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success {
  NSArray *savedBounds = [self faceDetectionBoundsForURL:url];
  if (savedBounds) {
    success([savedBounds firstObject]);
  } else {
    [self getFaceBoundsInImage:image
                       failure:failure
                       success:^(NSArray *faceBounds) {
                         [self cacheFaceDetectionBounds:faceBounds forURL:url];
                         success([faceBounds firstObject]);
                       }];
  }
}

- (void)detectFaceBoundsInImage:(UIImage *)image imageMetadata:(MWKImage *)imageMetadata failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success {
  NSArray *savedBounds = imageMetadata.allNormalizedFaceBounds;
  if (savedBounds) {
    success([savedBounds firstObject]);
  } else {
    [self getFaceBoundsInImage:image
                       failure:failure
                       success:^(NSArray *faceBounds) {
                         imageMetadata.allNormalizedFaceBounds = faceBounds;
                         [imageMetadata save];
                         success([faceBounds firstObject]);
                       }];
  }
}

- (void)getFaceBoundsInImage:(UIImage *)image failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
  [[CIDetector wmf_sharedFaceDetector] wmf_detectFeaturelessFacesInImage:image
                                                                 failure:failure
                                                                 success:^(NSArray *features) {
                                                                   NSArray<NSValue *> *faceBounds = [image wmf_normalizeAndConvertBoundsFromCIFeatures:features];
                                                                   success(faceBounds);
                                                                 }];
}

#pragma mark - Cache methods

- (void)cacheFaceDetectionBounds:(NSArray *)bounds forURL:(NSURL *)url {
  NSParameterAssert(url);
  if (!url) {
    return;
  }
  if (!bounds) {
    bounds = @[];
  }

  [self.faceDetectionBoundsKeyedByURL setObject:bounds forKey:url];
}

- (NSArray *)faceDetectionBoundsForURL:(NSURL *)url {
  return [self.faceDetectionBoundsKeyedByURL objectForKey:url];
}

- (void)clearCache {
  [self.faceDetectionBoundsKeyedByURL removeAllObjects];
}

@end
