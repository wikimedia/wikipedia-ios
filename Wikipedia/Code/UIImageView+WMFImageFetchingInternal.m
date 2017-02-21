#import "UIImageView+WMFImageFetchingInternal.h"
#import "UIImageView+WMFImageFetching.h"
#import "UIImageView+WMFContentOffset.h"
#import "UIImage+WMFNormalization.h"
#import "CIDetector+WMFFaceDetection.h"
#import "WMFFaceDetectionCache.h"
#import "UIImageView+WMFPlaceholder.h"
#import <WMF/WMF-Swift.h>

static const char *const MWKURLAssociationKey = "MWKURL";

static const char *const MWKURLToCancelAssociationKey = "MWKURLToCancel";

static const char *const MWKImageAssociationKey = "MWKImage";

static const char *const WMFImageControllerAssociationKey = "WMFImageController";

@implementation UIImageView (WMFImageFetchingInternal)

#pragma mark - Associated Objects

- (WMFImageController *__nullable)wmf_imageController {
    WMFImageController *controller = [self bk_associatedValueForKey:WMFImageControllerAssociationKey];
    if (!controller) {
        controller = [WMFImageController sharedInstance];
    }
    return controller;
}

- (void)wmf_setImageController:(nullable WMFImageController *)imageController {
    [self bk_associateValue:imageController withKey:WMFImageControllerAssociationKey];
}

- (MWKImage *__nullable)wmf_imageMetadata {
    return [self bk_associatedValueForKey:MWKImageAssociationKey];
}

- (void)wmf_setImageMetadata:(nullable MWKImage *)imageMetadata {
    [self bk_associateValue:imageMetadata withKey:MWKImageAssociationKey];
}

- (NSURL *__nullable)wmf_imageURL {
    return [self bk_associatedValueForKey:MWKURLAssociationKey];
}

- (void)wmf_setImageURL:(nullable NSURL *)imageURL {
    [self bk_associateValue:imageURL withKey:MWKURLAssociationKey];
}

- (NSURL *__nullable)wmf_imageURLToCancel {
    return [self bk_associatedValueForKey:MWKURLToCancelAssociationKey];
}

- (void)wmf_setImageURLToCancel:(nullable NSURL *)imageURL {
    [self bk_associateValue:imageURL withKey:MWKURLToCancelAssociationKey];
}

#pragma mark - Cached Image

- (UIImage *)wmf_cachedImage {
    UIImage *cachedImage = [self.wmf_imageController cachedImageInMemoryWithURL:[self wmf_imageURLToFetch]];
    return cachedImage;
}

#pragma mark - Face Detection

+ (WMFFaceDetectionCache *)faceDetectionCache {
    return [WMFFaceDetectionCache sharedCache];
}

- (BOOL)wmf_imageRequiresFaceDetection {
    if (self.wmf_imageURL) {
        return [[[self class] faceDetectionCache] imageAtURLRequiresFaceDetection:self.wmf_imageURL];
    } else {
        return [[[self class] faceDetectionCache] imageRequiresFaceDetection:self.wmf_imageMetadata];
    }
}

- (NSValue *)wmf_faceBoundsInImage:(UIImage *)image {
    if (self.wmf_imageURL) {
        return [[[self class] faceDetectionCache] faceBoundsForURL:self.wmf_imageURL];
    } else {
        return [[[self class] faceDetectionCache] faceBoundsForImageMetadata:self.wmf_imageMetadata];
    }
}

- (void)wmf_getFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success {
    if (self.wmf_imageURL) {
        [[[self class] faceDetectionCache] detectFaceBoundsInImage:image onGPU:onGPU URL:self.wmf_imageURL failure:failure success:success];
    } else {
        [[[self class] faceDetectionCache] detectFaceBoundsInImage:image onGPU:onGPU imageMetadata:self.wmf_imageMetadata failure:failure success:success];
    }
}

#pragma mark - Set Image

- (void)wmf_fetchImageDetectFaces:(BOOL)detectFaces onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    NSAssert([NSThread isMainThread], @"Interaction with a UIImageView should only happen on the main thread");

    NSURL *imageURL = [self wmf_imageURLToFetch];

    if (!imageURL) {
        failure([NSError wmf_cancelledError]);
        return;
    }

    UIImage *cachedImage = [self wmf_cachedImage];
    if (cachedImage) {
        [self wmf_setImage:cachedImage detectFaces:detectFaces onGPU:onGPU animated:NO failure:failure success:success];
        return;
    }

    @weakify(self);
    self.wmf_imageURLToCancel = imageURL;
    [self.wmf_imageController fetchImageWithURL:imageURL
                                        failure:failure
                                        success:^(WMFImageDownload *_Nonnull download) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                @strongify(self);
                                                if (!WMF_EQUAL([self wmf_imageURLToFetch], isEqual:, imageURL)) {
                                                    self.wmf_imageURLToCancel = nil;
                                                    failure([NSError wmf_cancelledError]);
                                                } else {
                                                    self.wmf_imageURLToCancel = nil;
                                                    [self wmf_setImage:download.image detectFaces:detectFaces onGPU:onGPU animated:YES failure:failure success:success];
                                                }
                                            });
                                        }];
}

- (void)wmf_setImage:(UIImage *)image
         detectFaces:(BOOL)detectFaces
               onGPU:(BOOL)onGPU
            animated:(BOOL)animated
             failure:(WMFErrorHandler)failure
             success:(WMFSuccessHandler)success {
    NSAssert([NSThread isMainThread], @"Interaction with a UIImageView should only happen on the main thread");
    if (!detectFaces) {
        [self wmf_setImage:image faceBoundsValue:nil animated:animated failure:failure success:success];
        return;
    }

    if (![self wmf_imageRequiresFaceDetection]) {
        NSValue *faceBoundsValue = [self wmf_faceBoundsInImage:image];
        [self wmf_setImage:image faceBoundsValue:faceBoundsValue animated:animated failure:failure success:success];
        return;
    }

    NSURL *imageURL = [self wmf_imageURLToFetch];
    [self wmf_getFaceBoundsInImage:image
                             onGPU:onGPU
                           failure:failure
                           success:^(NSValue *bounds) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (!WMF_EQUAL([self wmf_imageURLToFetch], isEqual:, imageURL)) {
                                       failure([NSError wmf_cancelledError]);
                                   } else {
                                       [self wmf_setImage:image faceBoundsValue:bounds animated:animated failure:failure success:success];
                                   }
                               });
                           }];
}

- (void)wmf_setImage:(UIImage *)image
     faceBoundsValue:(nullable NSValue *)faceBoundsValue
            animated:(BOOL)animated
             failure:(WMFErrorHandler)failure
             success:(WMFSuccessHandler)success {
    NSAssert([NSThread isMainThread], @"Interaction with a UIImageView should only happen on the main thread");
    CGRect faceBounds = [faceBoundsValue CGRectValue];
    if (!CGRectIsEmpty(faceBounds)) {
        [self wmf_cropContentsByVerticallyCenteringFrame:[image wmf_denormalizeRect:faceBounds]
                                     insideBoundsOfImage:image];
    } else {
        [self wmf_topAlignContentsRect:image];
}
    
    dispatch_block_t animations = ^{
        [self wmf_hidePlaceholder];
    };
    
    self.image = image;
    if (animated) {
        [UIView animateWithDuration:[CATransaction animationDuration] animations:animations completion:^(BOOL finished) {
            success();
        }];
    } else {
        animations();
        success();
    }
}

- (void)wmf_cancelImageDownload {
    [self.wmf_imageController cancelFetchForURL:[self wmf_imageURLToCancel]];
    self.wmf_imageURL = nil;
    self.wmf_imageMetadata = nil;
    self.wmf_imageURLToCancel = nil;
}

@end
