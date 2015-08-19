//
//  UIImageView+MWKImage.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIImageView+MWKImageInternal.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"
#import <BlocksKit/BlocksKit.h>

#import "MWKImage+FaceDetection.h"
#import "MWKDataStore.h"

#import "UIImage+WMFNormalization.h"
#import "UIImageView+WMFContentOffset.h"
#import "CIDetector+WMFFaceDetection.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF DDLogLevelVerbose

NS_ASSUME_NONNULL_BEGIN

BOOL WMFShouldDetectFacesForMetadataWithOptions(MWKImage* imageMetadata, WMFImageOptions options) {
    return (options & WMFImageOptionCenterFace) && !imageMetadata.didDetectFaces;
}

static const char* const MWKImageAssociationKey = "MWKImage";

static const char* const WMFImageControllerAssociationKey = "WMFImageController";

@implementation UIImageView (MWKImage)

- (void)wmf_resetImageMetadata {
    [self wmf_setMetadata:nil controller:nil];
}

- (void)wmf_setImageWithFaceDetectionFromMetadata:(MWKImage*)imageMetadata {
    [self wmf_setImageFromMetadata:imageMetadata
                           options:WMFImageOptionCenterFace
                         withBlock:nil
                        completion:nil
                           onError:nil];
}

- (void)wmf_setImageFromMetadata:(MWKImage*)imageMetadata
                         options:(WMFImageOptions)options
                       withBlock:(WMFSetImageBlock __nullable)setImageBlock
                      completion:(void (^ __nullable)(BOOL))completion
                         onError:(void (^ __nullable)(NSError*))failure {
    [self wmf_setImageFromMetadata:imageMetadata
                           options:options
                         withBlock:setImageBlock
                        completion:completion
                           onError:failure
                   usingController:[WMFImageController sharedInstance]];
}

- (BOOL)wmf_setCachedImageForMetadata:(MWKImage*)imageMetadata
                              options:(WMFImageOptions)options
                        setImageBlock:(WMFSetImageBlock __nullable)setImageBlock
                           completion:(void (^ __nullable)(BOOL))completion {
    return [self wmf_setCachedImageForMetadata:imageMetadata
                                       options:options
                                 setImageBlock:setImageBlock
                                    completion:completion
                               usingController:[WMFImageController sharedInstance]];
}

@end

@implementation UIImageView (WMFAssociatedObjects)

- (void)wmf_setMetadata:(MWKImage* __nullable)imageMetadata controller:(WMFImageController* __nullable)imageController {
    [self.wmf_imageController cancelFetchForURL:self.wmf_imageMetadata.sourceURL];

    self.wmf_imageController = imageController;
    self.wmf_imageMetadata   = imageMetadata;

    if (!imageMetadata) {
        // reset our content offset in case a "regular" image is set
        [self wmf_resetContentOffset];
    }
}

- (WMFImageController* __nullable)wmf_imageController {
    return [self bk_associatedValueForKey:WMFImageControllerAssociationKey];
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

@end

@implementation UIImageView (MWKImageInternal)

- (void)wmf_setImageFromMetadata:(MWKImage*)imageMetadata
                         options:(WMFImageOptions)options
                       withBlock:(WMFSetImageBlock __nullable)setImageBlock
                      completion:(void (^ __nullable)(BOOL))completion
                         onError:(void (^ __nullable)(NSError*))failure
                 usingController:(WMFImageController*)imageController {
    NSAssert(imageMetadata, @"Illegal attempt to set image from nil metadata. If needed, call wmf_resetImageMetadata.");
    if (WMF_EQUAL(self.wmf_imageMetadata, isEqualToImage:, imageMetadata)) {
        return;
    }

    BOOL const didSetSynchronously = [self wmf_setCachedImageForMetadata:imageMetadata
                                                                 options:options
                                                           setImageBlock:setImageBlock
                                                              completion:completion
                                                         usingController:imageController];
    if (didSetSynchronously) {
        return;
    }

    [self wmf_setMetadata:imageMetadata controller:imageController];
    if (!self.wmf_imageMetadata) {
        return;
    }

    // async path, fetch the image then run same logic as above (face detection if necessary, then set)
    @weakify(self);
    [imageController fetchImageWithURL:[imageMetadata sourceURL]]
    .then(^id (WMFImageDownload* download) {
        @strongify(self);
        if (!WMF_EQUAL(self.wmf_imageMetadata, isEqualToImage:, imageMetadata)) {
            return [NSError cancelledError];
        } else if (WMFShouldDetectFacesForMetadataWithOptions(imageMetadata, options)) {
            return [imageMetadata setFaceBoundsFromFeaturesInImage:download.image].then(^(MWKImage* _) {
                [imageMetadata save];
                return download.image;
            });
        } else {
            return download.image;
        }
    })
    .then(^(UIImage* image) {
        @strongify(self);
        [self wmf_setImage:image
               forMetadata:imageMetadata
                   options:options
                 withBlock:setImageBlock
                completion:completion
                  animated:YES];
    })
    .catch(^(NSError* error) {
        // TODO: show error in UI
        @strongify(self);
        self.wmf_imageMetadata = nil;
        DDLogError(@"Failed to fetch image from %@. %@", [imageMetadata sourceURL], error);
        if (failure) {
            failure(error);
        }
    });
}

- (BOOL)wmf_setCachedImageForMetadata:(MWKImage*)imageMetadata
                              options:(WMFImageOptions)options
                        setImageBlock:(WMFSetImageBlock __nullable)setImageBlock
                           completion:(void (^ __nullable)(BOOL))completion
                      usingController:(WMFImageController*)controller {
    NSAssert(imageMetadata, @"Illegal attempt to set image from nil metadata. If needed, call wmf_resetImageMetadata.");

    if (WMF_EQUAL(self.wmf_imageMetadata, isEqualToImage:, imageMetadata)) {
        return NO;
    }

    UIImage* cachedImage = [controller cachedImageInMemoryWithURL:imageMetadata.sourceURL];
    if (!cachedImage) {
        DDLogVerbose(@"No cached image found for %@", imageMetadata.sourceURL);
        [self wmf_resetImageMetadata];
    } else if (WMFShouldDetectFacesForMetadataWithOptions(imageMetadata, options)) {
        DDLogInfo(@"%@ requires face detection, unable to set cached image.", imageMetadata);
        [self wmf_resetImageMetadata];
    } else {
        [self wmf_setMetadata:imageMetadata controller:controller];
        [self wmf_setImage:cachedImage
               forMetadata:imageMetadata
                   options:options
                 withBlock:setImageBlock
                completion:completion
                  animated:NO];
        return YES;
    }
    return NO;
}

- (void)wmf_setImage:(UIImage*)image
         forMetadata:(MWKImage*)imageMetadata
             options:(WMFImageOptions)options
           withBlock:(WMFSetImageBlock __nullable)setImageBlock
          completion:(void (^ __nullable)(BOOL))completion
            animated:(BOOL)animated {
    NSAssert(!((options & WMFImageOptionNeverAnimate) && (options & WMFImageOptionAlwaysAnimate)),
             @"Illegal attempt to set both always & never animate!");

    // set default setImageBlock if caller passed nil
    if (!setImageBlock) {
        setImageBlock = ^(UIImageView* imgView, UIImage* img, MWKImage* _) { imgView.image = img; };
    }

    if (!WMF_EQUAL(self.wmf_imageMetadata, isEqualToImage:, imageMetadata)) {
        DDLogInfo(@"%@ is skipping setting image for %@ since %@ was set", self, self.wmf_imageMetadata, imageMetadata);
        return;
    }

    if (options & WMFImageOptionCenterFace) {
        self.contentMode = UIViewContentModeScaleAspectFill;
        if (CGRectIsEmpty(imageMetadata.firstFaceBounds)) {
            [self wmf_resetContentOffset];
        } else {
            [self wmf_setContentOffsetToCenterRect:[image wmf_denormalizeRect:imageMetadata.firstFaceBounds]
                                             image:image];
        }
    } else {
        // if we're not centering the face, ensure contentsRect is normal
        [self wmf_resetContentOffset];
    }

    float const duration = WMFApplyImageOptionsToAnimationFlag(options, animated) ?
                           [CATransaction animationDuration] : 0.0;

    [UIView transitionWithView:self
                      duration:duration
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        NSParameterAssert(setImageBlock);
        setImageBlock(self, image, imageMetadata);
    }
                    completion:^(BOOL finished) {
        if (!finished) {
            DDLogWarn(@"Transition to %@ with duration %f in %@ didn't finish!",
                      imageMetadata.sourceURL, duration, self);
        }
        if (completion) {
            completion(finished);
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
