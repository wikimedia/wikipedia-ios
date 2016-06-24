//
//  UIImageView+WMFImageFetchingInternal.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIImageView+WMFImageFetchingInternal.h"
#import "Wikipedia-Swift.h"

#import <BlocksKit/BlocksKit.h>

#import "MWKDataStore.h"
#import "MWKImage.h"

#import "UIImageView+WMFContentOffset.h"
#import "UIImage+WMFNormalization.h"
#import "CIDetector+WMFFaceDetection.h"
#import "WMFFaceDetectionCache.h"

static const char* const MWKURLAssociationKey = "MWKURL";

static const char* const MWKImageAssociationKey = "MWKImage";

static const char* const WMFImageControllerAssociationKey = "WMFImageController";

@implementation UIImageView (WMFImageFetchingInternal)

#pragma mark - Associated Objects

- (WMFImageController* __nullable)wmf_imageController {
    WMFImageController* controller = [self bk_associatedValueForKey:WMFImageControllerAssociationKey];
    if (!controller) {
        controller = [WMFImageController sharedInstance];
    }
    return controller;
}

- (void)wmf_setImageController:(nullable WMFImageController*)imageController {
    [self bk_associateValue:imageController withKey:WMFImageControllerAssociationKey];
}

- (MWKImage* __nullable)wmf_imageMetadata {
    return [self bk_associatedValueForKey:MWKImageAssociationKey];
}

- (void)wmf_setImageMetadata:(nullable MWKImage*)imageMetadata {
    [self bk_associateValue:imageMetadata withKey:MWKImageAssociationKey];
}

- (NSURL* __nullable)wmf_imageURL {
    return [self bk_associatedValueForKey:MWKURLAssociationKey];
}

- (void)wmf_setImageURL:(nullable NSURL*)imageURL {
    [self bk_associateValue:imageURL withKey:MWKURLAssociationKey];
}

#pragma mark - Cached Image

- (UIImage*)wmf_cachedImage {
    UIImage* cachedImage = [self.wmf_imageController cachedImageInMemoryWithURL:[self wmf_imageURLToFetch]];
    return cachedImage;
}

- (NSURL*)wmf_imageURLToFetch {
    return self.wmf_imageURL ? : self.wmf_imageMetadata.sourceURL;
}

#pragma mark - Face Detection

+ (WMFFaceDetectionCache*)faceDetectionCache {
    static WMFFaceDetectionCache* _faceDetectionCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _faceDetectionCache = [[WMFFaceDetectionCache alloc] init];
    });
    return _faceDetectionCache;
}

- (BOOL)wmf_imageRequiresFaceDetection {
    if (self.wmf_imageURL) {
        return [[[self class] faceDetectionCache] imageAtURLRequiresFaceDetection:self.wmf_imageURL];
    } else {
        return [[[self class] faceDetectionCache] imageRequiresFaceDetection:self.wmf_imageMetadata];
    }
}

- (NSValue*)wmf_faceBoundsInImage:(UIImage*)image {
    if (self.wmf_imageURL) {
        return [[[self class] faceDetectionCache] faceBoundsForURL:self.wmf_imageURL];
    } else {
        return [[[self class] faceDetectionCache] faceBoundsForImageMetadata:self.wmf_imageMetadata];
    }
}

- (AnyPromise*)wmf_getFaceBoundsInImage:(UIImage*)image {
    if (self.wmf_imageURL) {
        return [[[self class] faceDetectionCache] detectFaceBoundsInImage:image URL:self.wmf_imageURL];
    } else {
        return [[[self class] faceDetectionCache] detectFaceBoundsInImage:image imageMetadata:self.wmf_imageMetadata];
    }
}

#pragma mark - Set Image

- (AnyPromise*)wmf_fetchImageDetectFaces:(BOOL)detectFaces {
    NSURL* imageURL = [self wmf_imageURLToFetch];

    if (!imageURL) {
        return [AnyPromise promiseWithValue:[NSError cancelledError]];
    }

    UIImage* cachedImage = [self wmf_cachedImage];
    if (cachedImage) {
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
                   animated:(BOOL)animated {
    if (!detectFaces) {
        return [self wmf_setImage:image faceBoundsValue:nil animated:animated];
    }

    if (![self wmf_imageRequiresFaceDetection]) {
        NSValue* faceBoundsValue = [self wmf_faceBoundsInImage:image];
        return [self wmf_setImage:image faceBoundsValue:faceBoundsValue animated:animated];
    }

    NSURL* imageURL = [self wmf_imageURLToFetch];
    return [self wmf_getFaceBoundsInImage:image]
           .then(^id (NSValue* bounds) {
        if (!WMF_EQUAL([self wmf_imageURLToFetch], isEqual:, imageURL)) {
            return [NSError cancelledError];
        } else {
            return [self wmf_setImage:image faceBoundsValue:bounds animated:animated];
        }
    });
}

- (AnyPromise*)wmf_setImage:(UIImage*)image
            faceBoundsValue:(nullable NSValue*)faceBoundsValue
                   animated:(BOOL)animated {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        CGRect faceBounds = [faceBoundsValue CGRectValue];
        if (!CGRectIsEmpty(faceBounds)) {
            [self wmf_cropContentsByVerticallyCenteringFrame:[image wmf_denormalizeRect:faceBounds]
                                         insideBoundsOfImage:image];
        } else {
            [self wmf_resetContentsRect];
        }

        [UIView transitionWithView:self
                          duration:animated ? [CATransaction animationDuration] : 0.0
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            self.contentMode = UIViewContentModeScaleAspectFill;
            self.backgroundColor = [UIColor whiteColor];
            self.image = image;
        }
                        completion:^(BOOL finished) {
            resolve(nil);
        }];
    }];
}

- (void)wmf_cancelImageDownload {
    [self.wmf_imageController cancelFetchForURL:[self wmf_imageURLToFetch]];
    self.wmf_imageURL      = nil;
    self.wmf_imageMetadata = nil;
}

@end

