#import <WMF/WMFFaceDetectionCache.h>
#import <WMF/CIDetector+WMFFaceDetection.h>
#import "UIImage+WMFNormalization.h"
#import <WMF/WMFImageURLParsing.h>

@interface WMFFaceDetectionCache ()

@property (nonatomic, strong) NSCache *faceDetectionBoundsKeyedByURL;

@end

@implementation WMFFaceDetectionCache

- (instancetype)init {
    self = [super init];
    if (self) {
        self.faceDetectionBoundsKeyedByURL = [[NSCache alloc] init];
    }
    return self;
}

+ (WMFFaceDetectionCache *)sharedCache {
    static WMFFaceDetectionCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[WMFFaceDetectionCache alloc] init];
    });
    return sharedCache;
}

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL *)url {
    return ([self faceDetectionBoundsForURL:url] == nil);
}

- (NSValue *)faceBoundsForURL:(NSURL *)url {
    return [[self faceDetectionBoundsForURL:url] firstObject];
}

- (void)detectFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU URL:(NSURL *)url failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success {
    NSArray *savedBounds = [self faceDetectionBoundsForURL:url];
    if (savedBounds) {
        success([savedBounds firstObject]);
    } else {
        [self getFaceBoundsInImage:image
                             onGPU:onGPU
                           failure:failure
                           success:^(NSArray *faceBounds) {
                               [self cacheFaceDetectionBounds:faceBounds forURL:url];
                               success([faceBounds firstObject]);
                           }];
    }
}

- (void)getFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    CIDetector *detector = onGPU ? [CIDetector wmf_sharedGPUFaceDetector] : [CIDetector wmf_sharedCPUFaceDetector];
    [detector wmf_detectFeaturelessFacesInImage:image
                                    withFailure:failure
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
    NSURL *key = [self sizeInvariantURLKeyForFullImageURL:url];
    [self.faceDetectionBoundsKeyedByURL setObject:bounds forKey:key];
}

- (NSArray *)faceDetectionBoundsForURL:(NSURL *)url {
    NSURL *key = [self sizeInvariantURLKeyForFullImageURL:url];
    return [self.faceDetectionBoundsKeyedByURL objectForKey:key];
}

- (void)clearCache {
    [self.faceDetectionBoundsKeyedByURL removeAllObjects];
}

// Face bounds are stored as unit rects so no need to recalculate for size variants.
// i.e. if you have a unit rect for the 240px version of an image, the 640px version of the same image has the same unit rect.
- (NSURL *)sizeInvariantURLKeyForFullImageURL: (NSURL *)url {
    NSString *imgNameWithoutSizePrefix = WMFParseImageNameFromSourceURL(url.absoluteString);
    if (!imgNameWithoutSizePrefix) {
        return url;
    }
    // Reminder: the url returned is deliberately *not* a valid url to the image. Key needs to be unique *only* on host and image name w/o size prefix.
    NSURL *sizeInvariantURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", url.host, imgNameWithoutSizePrefix]];
    return sizeInvariantURL;
}

@end
