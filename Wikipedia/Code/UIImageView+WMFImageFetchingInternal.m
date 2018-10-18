@import FLAnimatedImage;
#import "UIImageView+WMFImageFetchingInternal.h"
#import <WMF/UIImageView+WMFImageFetching.h>
#import "UIImageView+WMFContentOffset.h"
#import "UIImage+WMFNormalization.h"
#import <WMF/CIDetector+WMFFaceDetection.h>
#import <WMF/WMFFaceDetectionCache.h>
#import <WMF/WMF-Swift.h>

static const char *const MWKURLAssociationKey = "MWKURL";

static const char *const MWKURLToCancelAssociationKey = "MWKURLToCancel";

static const char *const MWKTokenToCancelAssociationKey = "MWKTokenToCancel";

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

- (NSString *__nullable)wmf_imageTokenToCancel {
    return objc_getAssociatedObject(self, MWKTokenToCancelAssociationKey);
}

- (void)wmf_setImageTokenToCancel:(nullable NSString *)token {
    objc_setAssociatedObject(self, MWKTokenToCancelAssociationKey, token, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - Face Detection

+ (WMFFaceDetectionCache *)faceDetectionCache {
    return [WMFFaceDetectionCache sharedCache];
}

- (NSURL *)imageURLForFaceDetection {
    return self.wmf_imageURL ? self.wmf_imageURL : self.wmf_imageMetadata.sourceURL;
}

- (BOOL)wmf_imageRequiresFaceDetection {
    return [[[self class] faceDetectionCache] imageAtURLRequiresFaceDetection:[self imageURLForFaceDetection]];
}

- (NSValue *)wmf_faceBoundsInImage:(UIImage *)image {
    return [[[self class] faceDetectionCache] faceBoundsForURL:[self imageURLForFaceDetection]];
}

- (void)wmf_getFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success {
    [[[self class] faceDetectionCache] detectFaceBoundsInImage:image onGPU:onGPU URL:[self imageURLForFaceDetection] failure:failure success:success];
}

#pragma mark - Set Image

- (void)wmf_fetchImageDetectFaces:(BOOL)detectFaces onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    NSAssert([NSThread isMainThread], @"Interaction with a UIImageView should only happen on the main thread");

    NSURL *imageURL = [self wmf_imageURLToFetch];
    if (!imageURL) {
        failure([NSError wmf_cancelledError]);
        return;
    }

    WMFImage *memoryCachedImage = [self.wmf_imageController memoryCachedImageWithURL:imageURL];
    if (memoryCachedImage) {
        self.wmf_imageURLToCancel = nil;
        self.wmf_imageTokenToCancel = nil;
        [self wmf_setImage:memoryCachedImage.staticImage animatedImage:memoryCachedImage.animatedImage detectFaces:detectFaces onGPU:onGPU animated:NO failure:failure success:success];
        return;
    }

    @weakify(self);
    self.wmf_imageURLToCancel = imageURL;
    self.wmf_imageTokenToCancel = [self.wmf_imageController fetchImageWithURL:imageURL
                                                                     priority:0.5
                                                                      failure:^(NSError * _Nonnull error) {
                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                              if (failure) {
                                                                                  failure(error);
                                                                              }
                                                                          });
                                                                      }
                                                                      success:^(WMFImageDownload *_Nonnull download) {
                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                              @strongify(self);
                                                                              self.wmf_imageURLToCancel = nil;
                                                                              self.wmf_imageTokenToCancel = nil;
                                                                              if (!WMF_EQUAL([self wmf_imageURLToFetch], isEqual:, imageURL)) {
                                                                                  failure([NSError wmf_cancelledError]);
                                                                              } else {
                                                                                  [self wmf_setImage:download.image.staticImage animatedImage:download.image.animatedImage detectFaces:detectFaces onGPU:onGPU animated:download.originRawValue != [WMFImageDownload imageOriginMemory] failure:failure success:success];
                                                                              }
                                                                          });
                                                                      }];
}

- (void)wmf_setImage:(UIImage *)image
       animatedImage:(FLAnimatedImage *)animatedImage
         detectFaces:(BOOL)detectFaces
               onGPU:(BOOL)onGPU
            animated:(BOOL)animated
             failure:(WMFErrorHandler)failure
             success:(WMFSuccessHandler)success {
    NSAssert([NSThread isMainThread], @"Interaction with a UIImageView should only happen on the main thread");
    if (!detectFaces) {
        [self wmf_setImage:image animatedImage:animatedImage detectFaces:detectFaces faceBoundsValue:nil animated:animated failure:failure success:success];
        return;
    }

    if (![self wmf_imageRequiresFaceDetection]) {
        NSValue *faceBoundsValue = [self wmf_faceBoundsInImage:image];
        [self wmf_setImage:image animatedImage:animatedImage detectFaces:detectFaces faceBoundsValue:faceBoundsValue animated:animated failure:failure success:success];
        return;
    }

    NSURL *imageURL = [self wmf_imageURLToFetch];
    [self wmf_getFaceBoundsInImage:image
                             onGPU:onGPU
                           failure:^(NSError * _Nonnull error) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (failure) {
                                       failure(error);
                                   }
                               });
                           }
                           success:^(NSValue *bounds) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (!WMF_EQUAL([self wmf_imageURLToFetch], isEqual:, imageURL)) {
                                       failure([NSError wmf_cancelledError]);
                                   } else {
                                       [self wmf_setImage:image animatedImage:animatedImage detectFaces:detectFaces faceBoundsValue:bounds animated:animated failure:failure success:success];
                                   }
                               });
                           }];
}

- (void)wmf_setImage:(UIImage *)image
       animatedImage:(FLAnimatedImage *)animatedImage
         detectFaces:(BOOL)detectFaces
     faceBoundsValue:(nullable NSValue *)faceBoundsValue
            animated:(BOOL)animated
             failure:(WMFErrorHandler)failure
             success:(WMFSuccessHandler)success {
    NSAssert([NSThread isMainThread], @"Interaction with a UIImageView should only happen on the main thread");

    if (detectFaces) {
        BOOL isFaceBigEnough = NO;
        CGRect unitFaceBounds = [faceBoundsValue CGRectValue];
        CGRect faceBounds = CGRectZero;
        if (!CGRectIsEmpty(unitFaceBounds)) {
            faceBounds = [image wmf_denormalizeRect:unitFaceBounds];
            CGFloat faceArea = faceBounds.size.width * faceBounds.size.height;
            CGFloat imageArea = image.size.width * image.size.height;
            CGFloat faceProportionOfImage = faceArea / MAX(imageArea, 0.0000001);
            // Reminder: "0.0178" of the area of a 640x640 image would be roughly 85x85.
            isFaceBigEnough = (faceProportionOfImage >= 0.0178);
        }
        if (isFaceBigEnough) {
            [self wmf_cropContentsByVerticallyCenteringFrame:faceBounds
                                         insideBoundsOfImage:image];
        } else {
            [self wmf_topAlignContentsRect:image];
        }
    } else {
        [self wmf_resetContentsRect];
    }

    if ([self isKindOfClass:[FLAnimatedImageView class]] && animatedImage) {
        FLAnimatedImageView *animatedImageView = ((FLAnimatedImageView *)self);
        animatedImageView.animatedImage = animatedImage;
        success();
    } else {
        //  for now, keep the unanimated behavior, ignore the animated parameter
        //        dispatch_block_t animations = ^{
        if (image) {
            self.backgroundColor = [UIColor whiteColor];
        }
        self.image = image;
        //        };
        //        if (animated) {
        //            [UIView transitionWithView:self
        //                              duration:[CATransaction animationDuration]
        //                               options:UIViewAnimationOptionTransitionCrossDissolve
        //                            animations:animations
        //                            completion:^(BOOL finished) {
        //                                success();
        //                            }];
        //        } else {
        //            animations();
        success();
        //        }
    }
}

- (void)wmf_cancelImageDownload {
    [self.wmf_imageController cancelFetchWithURL:[self wmf_imageURLToCancel] token:[self wmf_imageTokenToCancel]];
    self.wmf_imageURL = nil;
    self.wmf_imageMetadata = nil;
    self.wmf_imageURLToCancel = nil;
    self.wmf_imageTokenToCancel = nil;
}

@end
