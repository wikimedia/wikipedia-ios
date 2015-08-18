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

static const char* const MWKImageAssociationKey = "MWKImage";

@implementation UIImageView (MWKImage)

- (void)wmf_resetImageMetadata {
    [self wmf_setImageFromMetadata:nil options:0 withBlock:nil completion:nil onError:nil];
}

- (void)wmf_setImageWithFaceDetectionFromMetadata:(MWKImage*)imageMetadata {
    [self wmf_setImageFromMetadata:imageMetadata
                           options:WMFImageOptionCenterFace
                         withBlock:nil
                        completion:nil
                           onError:nil];
}

- (void)wmf_setImageFromMetadata:(MWKImage* __nullable)imageMetadata
                         options:(WMFImageOptions)options
                       withBlock:(WMFSetImageBlock __nullable)setImageBlock
                      completion:(dispatch_block_t __nullable)completion
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
                           completion:(dispatch_block_t __nullable)completion {
    return [self wmf_setCachedImageForMetadata:imageMetadata
                                       options:options
                                 setImageBlock:setImageBlock
                                    completion:completion
                               usingController:[WMFImageController sharedInstance]];
}

@end

@implementation UIImageView (WMFAssociatedMWKImage)

- (MWKImage* __nullable)wmf_imageMetadata {
    return [self bk_associatedValueForKey:MWKImageAssociationKey];
}

- (void)setWmf_imageMetadata:(MWKImage* __nullable)imageMetadata {
    [self bk_associateValue:imageMetadata withKey:MWKImageAssociationKey];
}

@end

@implementation UIImageView (MWKImageInternal)

- (void)wmf_setImageFromMetadata:(MWKImage* __nullable)imageMetadata
                         options:(WMFImageOptions)options
                       withBlock:(WMFSetImageBlock __nullable)setImageBlock
                      completion:(dispatch_block_t __nullable)completion
                         onError:(void (^ __nullable)(NSError*))failure
                 usingController:(WMFImageController*)controller {
    NSAssert(!((options & WMFImageOptionNeverAnimate) && (options & WMFImageOptionAlwaysAnimate)),
             @"Illegal attempt to set both always & never animate!");
    if (WMF_EQUAL(self.wmf_imageMetadata, isEqualToImage:, imageMetadata)) {
        return;
    }

    BOOL didSetSynchronously = [self wmf_setCachedImageForMetadata:imageMetadata
                                                           options:options
                                                     setImageBlock:setImageBlock
                                                        completion:completion
                                                   usingController:controller];
    if (didSetSynchronously) {
        return;
    }

    [controller cancelFetchForURL:self.wmf_imageMetadata.sourceURL];

    self.wmf_imageMetadata = imageMetadata;

    if (!self.wmf_imageMetadata) {
        // reset our content offset in case a "regular" image is set
        [self wmf_resetContentOffset];
        return;
    }

    // async path, fetch the image then run same logic as above (face detection if necessary, then set)
    @weakify(self);
    [controller fetchImageWithURL:[imageMetadata sourceURL]]
    .then(^id (WMFImageDownload* download) {
        @strongify(self);
        if (!WMF_EQUAL(self.wmf_imageMetadata, isEqualToImage:, imageMetadata)) {
            return [NSError cancelledError];
        }
        return [imageMetadata setFaceBoundsFromFeaturesInImage:download.image].then(^(MWKImage* _) {
            [imageMetadata save];
            return download.image;
        });
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
                           completion:(dispatch_block_t __nullable)completion
                      usingController:(WMFImageController*)controller {
    // fast path, try to set image synchronously if stored in memory & face detection has already been run (if needed)
    UIImage* cachedImage = [controller cachedImageInMemoryWithURL:imageMetadata.sourceURL];
    if (cachedImage && (!(options & WMFImageOptionCenterFace) || imageMetadata.didDetectFaces)) {
        [controller cancelFetchForURL:self.wmf_imageMetadata.sourceURL];

        self.wmf_imageMetadata = imageMetadata;

        if (!self.wmf_imageMetadata) {
            // reset our content offset in case a "regular" image is set
            [self wmf_resetContentOffset];
        } else {
            [self wmf_setImage:cachedImage
                   forMetadata:imageMetadata
                       options:options
                     withBlock:setImageBlock
                    completion:completion
                      animated:NO];
        }
        return YES;
    }
    return NO;
}

- (void)wmf_setImage:(UIImage*)image
         forMetadata:(MWKImage*)imageMetadata
             options:(WMFImageOptions)options
           withBlock:(WMFSetImageBlock __nullable)setImageBlock
          completion:(dispatch_block_t __nullable)completion
            animated:(BOOL)animated {
    // set default setImageBlock if caller passed nil
    if (!setImageBlock) {
        setImageBlock = ^(UIImageView* imgView, UIImage* img, MWKImage* _) { imgView.image = img; };
    }

    if (!self) {
        // keep this return separate from the imageMetadata check to prevent misleading logs
        return;
    } else if (!WMF_EQUAL(self.wmf_imageMetadata, isEqualToImage:, imageMetadata)) {
        DDLogInfo(@"%@ is skipping setting image for %@ since %@ was set",
                  self, imageMetadata, self.wmf_imageMetadata);
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
        // if we're not centering the face, ensure the contentsRect is normal
        [self wmf_resetContentOffset];
    }
    animated = (animated && !(options & WMFImageOptionNeverAnimate)) || (options & WMFImageOptionAlwaysAnimate);
    [UIView transitionWithView:self
                      duration:animated ? [CATransaction animationDuration] : 0.0
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState
                    animations:^{
        setImageBlock(self, image, imageMetadata);
    }
                    completion:^(BOOL finished) {
        if (finished) {
            if (completion) {
                completion();
            }
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
