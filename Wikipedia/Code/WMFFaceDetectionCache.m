#import <WMF/WMFFaceDetectionCache.h>
#import <WMF/CIDetector+WMFFaceDetection.h>
#import "UIImage+WMFNormalization.h"
#import <WMF/WMFImageURLParsing.h>

@interface WMFFaceDetectionCache ()

@property (nonatomic, strong) NSCache *faceDetectionBoundsKeyedByURL;
@property (nonatomic, strong) NSOperationQueue *faceDetectionQueue;
@property (nonatomic, strong) NSMutableDictionary *faceDetectionOperationsKeyedByURL;

@end

@implementation WMFFaceDetectionCache

- (instancetype)init {
    self = [super init];
    if (self) {
        self.faceDetectionBoundsKeyedByURL = [[NSCache alloc] init];
        self.faceDetectionQueue = [[NSOperationQueue alloc] init];
        self.faceDetectionQueue.maxConcurrentOperationCount = 1;
        self.faceDetectionOperationsKeyedByURL = [[NSMutableDictionary alloc] init];
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
    if (!url) {
        failure([NSError errorWithDomain:WMFFaceDetectionErrorDomain code:WMFFaceDectionErrorUnknown userInfo:nil]);
        return;
    }
    NSArray *savedBounds = [self faceDetectionBoundsForURL:url];
    if (savedBounds) {
        success([savedBounds firstObject]);
    } else {
        CIDetector *detector = onGPU ? [CIDetector wmf_sharedGPUFaceDetector] : [CIDetector wmf_sharedCPUFaceDetector];
        NSOperation *op = [detector wmf_detectFeaturelessFacesInImage:image withFailure:^(NSError * _Nonnull error) {
            @synchronized (self) {
                [self.faceDetectionOperationsKeyedByURL removeObjectForKey:url];
            }
            failure(error);
        } success:^(id  _Nonnull features) {
            NSArray<NSValue *> *faceBounds = [image wmf_normalizeAndConvertBoundsFromCIFeatures:features];
            @synchronized (self) {
                [self.faceDetectionOperationsKeyedByURL removeObjectForKey:url];
                [self cacheFaceDetectionBounds:faceBounds forURL:url];
            }
            success([faceBounds firstObject]);
        }];
        if (!op) {
            failure([NSError errorWithDomain:WMFFaceDetectionErrorDomain code:WMFFaceDectionErrorUnknown userInfo:nil]);
            return;
        }
        @synchronized (self) {
            [self.faceDetectionOperationsKeyedByURL setObject:op forKey:url];
        }
        [self.faceDetectionQueue addOperation:op];
    }
}

- (void)cancelFaceDetectionForURL:(NSURL *)url {
    if (!url) {
        return;
    }
    @synchronized (self) {
        NSOperation *op = [self.faceDetectionOperationsKeyedByURL objectForKey:url];
        if (op) {
            [op cancel];
            [self.faceDetectionOperationsKeyedByURL removeObjectForKey:url];
        }
    }
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
