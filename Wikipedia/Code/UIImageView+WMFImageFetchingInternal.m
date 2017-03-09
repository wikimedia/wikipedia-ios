#import <FLAnimatedImage/FLAnimatedImage.h>
#import <FLAnimatedImage/FLAnimatedImageView.h>
#import "UIImageView+WMFImageFetchingInternal.h"
#import "UIImageView+WMFImageFetching.h"
#import "UIImageView+WMFContentOffset.h"
#import "UIImage+WMFNormalization.h"
#import "CIDetector+WMFFaceDetection.h"
#import "WMFFaceDetectionCache.h"
#import "UIImageView+WMFPlaceholder.h"
#import <WMF/WMF-Swift.h>
#import <SDWebImage/UIImage+GIF.h>

static const char *const MWKURLAssociationKey = "MWKURL";

static const char *const MWKURLToCancelAssociationKey = "MWKURLToCancel";

static const char *const MWKImageAssociationKey = "MWKImage";

static const char *const WMFImageControllerAssociationKey = "WMFImageController";

@implementation UIImageView (WMFImageFetchingInternal)

#pragma mark - Associated Objects

- (WMFImageController *__nullable)wmf_imageController {
    WMFImageController *controller = objc_getAssociatedObject(self, WMFImageControllerAssociationKey);
    if (!controller) {
        controller = [WMFImageController sharedInstance];
    }
    return controller;
}

- (void)wmf_setImageController:(nullable WMFImageController *)imageController {
    objc_setAssociatedObject(self, WMFImageControllerAssociationKey, imageController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (MWKImage *__nullable)wmf_imageMetadata {
    return objc_getAssociatedObject(self, MWKImageAssociationKey);
}

- (void)wmf_setImageMetadata:(nullable MWKImage *)imageMetadata {
    objc_setAssociatedObject(self, MWKImageAssociationKey, imageMetadata, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *__nullable)wmf_imageURL {
    return objc_getAssociatedObject(self, MWKURLAssociationKey);
}

- (void)wmf_setImageURL:(nullable NSURL *)imageURL {
    objc_setAssociatedObject(self, MWKURLAssociationKey, imageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *__nullable)wmf_imageURLToCancel {
    return objc_getAssociatedObject(self, MWKURLToCancelAssociationKey);
}

- (void)wmf_setImageURLToCancel:(nullable NSURL *)imageURL {
    objc_setAssociatedObject(self, MWKURLToCancelAssociationKey, imageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
                                                    [self wmf_setImage:download.image data:download.data detectFaces:detectFaces onGPU:onGPU animated:YES failure:failure success:success];
                                                }
                                            });
                                        }];
}

- (void)wmf_setImage:(UIImage *)image
                data:(NSData *)data
         detectFaces:(BOOL)detectFaces
               onGPU:(BOOL)onGPU
            animated:(BOOL)animated
             failure:(WMFErrorHandler)failure
             success:(WMFSuccessHandler)success {
    NSAssert([NSThread isMainThread], @"Interaction with a UIImageView should only happen on the main thread");
    if (!detectFaces) {
        [self wmf_setImage:image data:data detectFaces:detectFaces faceBoundsValue:nil animated:animated failure:failure success:success];
        return;
    }

    if (![self wmf_imageRequiresFaceDetection]) {
        NSValue *faceBoundsValue = [self wmf_faceBoundsInImage:image];
        [self wmf_setImage:image data:data detectFaces:detectFaces faceBoundsValue:faceBoundsValue animated:animated failure:failure success:success];
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
                                       [self wmf_setImage:image data:data detectFaces:detectFaces faceBoundsValue:bounds animated:animated failure:failure success:success];
                                   }
                               });
                           }];
}

- (void)wmf_setImage:(UIImage *)image
                data:(NSData *)data
         detectFaces:(BOOL)detectFaces
     faceBoundsValue:(nullable NSValue *)faceBoundsValue
            animated:(BOOL)animated
             failure:(WMFErrorHandler)failure
             success:(WMFSuccessHandler)success {
    NSAssert([NSThread isMainThread], @"Interaction with a UIImageView should only happen on the main thread");

    CGRect faceBounds = [faceBoundsValue CGRectValue];
    if (detectFaces) {
        CGFloat faceArea = faceBounds.size.width * faceBounds.size.height;
        if (!CGRectIsEmpty(faceBounds) && (faceArea >= 0.05)) {
            [self wmf_cropContentsByVerticallyCenteringFrame:[image wmf_denormalizeRect:faceBounds]
                                         insideBoundsOfImage:image];
        } else {
            [self wmf_topAlignContentsRect:image];
        }
    } else {
        [self wmf_resetContentsRect];
    }

    dispatch_block_t animations = ^{
        [self wmf_hidePlaceholder];
    };

    self.image = image;

    if ([self isKindOfClass:[FLAnimatedImageView class]] && image.isGIF && data) {
        FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
        if (animatedImage) {
            FLAnimatedImageView *animatedImageView = ((FLAnimatedImageView *)self);
            animatedImageView.animatedImage = animatedImage;
        }
    }

    if (animated) {
        [UIView animateWithDuration:[CATransaction animationDuration]
                         animations:animations
                         completion:^(BOOL finished) {
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
