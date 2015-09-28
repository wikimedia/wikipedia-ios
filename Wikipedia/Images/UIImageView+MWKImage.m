
#import "UIImageView+MWKImageInternal.h"
#import "Wikipedia-Swift.h"

#import <BlocksKit/BlocksKit.h>

#import "MWKDataStore.h"

#import "UIImage+WMFNormalization.h"
#import "UIImageView+WMFContentOffset.h"
#import "CIDetector+WMFFaceDetection.h"
#import "WMFFaceDetectionCache.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF DDLogLevelVerbose

NS_ASSUME_NONNULL_BEGIN

static const char* const MWKURLAssociationKey = "MWKURL";

static const char* const MWKImageAssociationKey = "MWKImage";

static const char* const WMFImageControllerAssociationKey = "WMFImageController";

@implementation UIImageView (WMFAssociatedObjects)

- (WMFImageController* __nullable)wmf_imageController {
    WMFImageController* controller = [self bk_associatedValueForKey:WMFImageControllerAssociationKey];
    if(!controller){
        controller = [WMFImageController sharedInstance];
    }
    return controller;
}

- (void)setWmf_imageController:(WMFImageController* __nullable)imageController {
    [self bk_associateValue:imageController withKey:WMFImageControllerAssociationKey];
}

- (MWKImage* __nullable)wmf_imageMetadata {
    return [self bk_associatedValueForKey:MWKImageAssociationKey];
}

- (void)setWmf_imageMetadata:(MWKImage* __nullable)imageMetadata {
    [self bk_associateValue:imageMetadata withKey:MWKImageAssociationKey];
}

- (NSURL* __nullable)wmf_imageURL {
    return [self bk_associatedValueForKey:MWKURLAssociationKey];
}

- (void)setWmf_imageURL:(MWKImage* __nullable)imageMetadata {
    [self bk_associateValue:imageMetadata withKey:MWKURLAssociationKey];
}

@end

@implementation UIImageView (MWKImageInternal)


#pragma mark - Cached Image

- (UIImage*)wmf_cachedImage{
    UIImage* cachedImage = [self.wmf_imageController cachedImageInMemoryWithURL:[self wmf_imageURLToFetch]];
    return cachedImage;
}

- (NSURL*)wmf_imageURLToFetch{
    NSURL* imageURL = self.wmf_imageURL;
    if(!imageURL){
        imageURL = self.wmf_imageMetadata.sourceURL;
    }
    return imageURL;
}

#pragma mark - Face Detection

+ (WMFFaceDetectionCache*)faceDetectionCache{
    static WMFFaceDetectionCache * _faceDetectionCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _faceDetectionCache = [[WMFFaceDetectionCache alloc] init];
    });
    return _faceDetectionCache;
}

- (NSValue*)wmf_faceBoundsInImage:(UIImage*)image{
    if(self.wmf_imageURL){
        return [[[self class] faceDetectionCache] faceBoundsForURL:self.wmf_imageURL];
    }else{
        return [[[self class] faceDetectionCache] faceBoundsForImageMetadata:self.wmf_imageMetadata];
    }
}

- (AnyPromise*)wmf_getFaceBoundsInImage:(UIImage*)image{
    if(self.wmf_imageURL){
        return [[[self class] faceDetectionCache] getFaceBoundsInImage:image URL:self.wmf_imageURL];
    }else{
        return [[[self class] faceDetectionCache] getFaceBoundsInImage:image imageMetadata:self.wmf_imageMetadata];
    }
}

#pragma mark - Set Image

- (AnyPromise*)wmf_fetchImageDetectFaces:(BOOL)detectFaces{
    
    NSURL* imageURL = [self wmf_imageURLToFetch];

    if(!imageURL){
        return [AnyPromise promiseWithValue:nil];
    }
    
    UIImage* cachedImage = [self wmf_cachedImage];
    if(cachedImage){
        return [self wmf_setImage:cachedImage detectFaces:detectFaces animated:NO];
    }
    
    @weakify(self);
    return [self.wmf_imageController fetchImageWithURL:imageURL]
    .then(^id (WMFImageDownload* download) {
        @strongify(self);
        if (!WMF_EQUAL([self wmf_imageURLToFetch], isEqual:, imageURL)) {
            return [NSError cancelledError];
        } else {
            return download.image;
        }
    })
    .then(^(UIImage* image) {
        @strongify(self);
        return [self wmf_setImage:image detectFaces:detectFaces animated:YES];
    });
    
}


- (AnyPromise*)wmf_setImage:(UIImage*)image
                detectFaces:(BOOL)detectFaces
                   animated:(BOOL)animated{

    if(!detectFaces){
        return [self wmf_setImage:image faceBoundsValue:nil animated:animated];
    }
    
    NSValue* faceBoundsValue = [self wmf_faceBoundsInImage:image];

    if(faceBoundsValue){
        return [self wmf_setImage:image faceBoundsValue:faceBoundsValue animated:animated];
    }
    
    return [self wmf_getFaceBoundsInImage:image]
    .then(^(NSValue* bounds) {
        return [self wmf_setImage:image faceBoundsValue:bounds animated:animated];
    });
}

- (AnyPromise*)wmf_setImage:(UIImage*)image
            faceBoundsValue:(nullable NSValue*)faceBoundsValue
                   animated:(BOOL)animated{
    
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver  _Nonnull resolve) {
        
        self.contentMode = UIViewContentModeScaleAspectFill;

        CGRect faceBounds = [faceBoundsValue CGRectValue];
        if (!CGRectIsEmpty(faceBounds)) {
            [self wmf_setContentOffsetToCenterRect:[image wmf_denormalizeRect:faceBounds]
                                             image:image];
        }
        
        [UIView transitionWithView:self
                          duration:animated ? [CATransaction animationDuration] : 0.0
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.image = image;
                        }
                        completion:^(BOOL finished) {
                            resolve(nil);
                        }];
    }];
}

- (void)wmf_cancelImageDownload {
    [self.wmf_imageController cancelFetchForURL:[self wmf_imageURLToFetch]];
}

@end

@implementation UIImageView (MWKImage)

- (void)wmf_reset {
    self.image = nil;
    [self wmf_resetContentOffset];
    [self wmf_cancelImageDownload];
    self.wmf_imageURL = nil;
    self.wmf_imageMetadata = nil;
}

- (void)wmf_setImageWithURL:(NSURL*)imageURL detectFaces:(BOOL)detectFaces{
    [self wmf_cancelImageDownload];
    self.wmf_imageURL = imageURL;
    self.wmf_imageMetadata = nil;
    [self wmf_fetchImageDetectFaces:detectFaces];
}


- (void)wmf_setImageWithMetadata:(MWKImage*)imageMetadata detectFaces:(BOOL)detectFaces{
    [self wmf_cancelImageDownload];
    self.wmf_imageMetadata = imageMetadata;
    self.wmf_imageURL = nil;
    [self wmf_fetchImageDetectFaces:detectFaces];
}

@end


NS_ASSUME_NONNULL_END
