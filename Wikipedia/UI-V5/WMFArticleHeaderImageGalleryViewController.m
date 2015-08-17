//
//  WMFHeaderGalleryDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleHeaderImageGalleryViewController.h"

// Utils
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "CIDetector+WMFFaceDetection.h"

// View
#import "WMFImageCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UIImageView+WMFContentOffset.h"
#import "UIImage+WMFNormalization.h"

// Model
#import "MWKArticle.h"
#import "MWKImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleHeaderImageGalleryViewController ()
@property (nonatomic, strong) CIDetector* faceDetector;
@end

@implementation WMFArticleHeaderImageGalleryViewController

- (CIDetector*)faceDetector {
    if (!_faceDetector) {
        _faceDetector = [CIDetector wmf_sharedLowAccuracyBackgroundFaceDetector];
    }
    return _faceDetector;
}

- (void)setImages:(NSArray* __nullable)images {
    if (WMF_EQUAL(_images, isEqualToArray:, images)) {
        return;
    }
    for (MWKImage* image in _images) {
        // TODO: use private downloader to prevent side effects
        [[WMFImageController sharedInstance] cancelFetchForURL:image.sourceURL];
    }
    _images          = [(images ? : @[]) wmf_reverseArrayIfApplicationIsRTL];
    self.currentPage = [_images wmf_startingIndexForApplicationLayoutDirection];
    if ([self isViewLoaded]) {
        [self.collectionView reloadData];
    }
}

- (void)setImagesFromArticle:(MWKArticle* __nonnull)article {
    if (article.isCached) {
        [self setImagesFromCachedArticle:article];
    } else {
        [self setImagesFromUncachedArticle:article];
    }
}

- (void)setImagesFromCachedArticle:(MWKArticle* __nonnull)article {
    NSParameterAssert(article.isCached);
    self.images = article.images.uniqueLargestVariants;
}

- (void)setImagesFromUncachedArticle:(MWKArticle* __nonnull)article {
    NSParameterAssert(!article.isCached);
    if (article.imageURL) {
        self.images = @[[[MWKImage alloc] initWithArticle:article sourceURLString:article.imageURL]];
    } else if (article.thumbnailURL) {
        self.images = @[[[MWKImage alloc] initWithArticle:article sourceURLString:article.thumbnailURL]];
    } else {
        self.images = nil;
    }
}

#pragma mark - UICollectionView Protocols

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    [self.delegate headerImageGallery:self didSelectImageAtIndex:indexPath.item];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFImageCollectionViewCell* cell =
        (WMFImageCollectionViewCell*)
        [collectionView dequeueReusableCellWithReuseIdentifier:[WMFImageCollectionViewCell wmf_nibName]
                                                  forIndexPath:indexPath];
    if (self.images.count == 0) {
        cell.imageView.image       = [UIImage imageNamed:@"lead-default"];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        return cell;
    }
    MWKImage* imageMetadata = self.images[indexPath.item];
    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:[imageMetadata sourceURL]]
    .then(^id (WMFImageDownload* download) {
        @strongify(self);
        UIImage* image = download.image;
        if (!self) {
            return [NSError cancelledError];
        } else {
            BOOL shouldAnimate = ![download.origin isEqualToString:[WMFImageDownload imageOriginMemory]];
            if (!imageMetadata.allNormalizedFaceBounds) {
                @weakify(self);
                return [self.faceDetector wmf_detectFeaturelessFacesInImage:image].then(^(NSArray* faces) {
                    @strongify(self);
                    imageMetadata.allNormalizedFaceBounds = [faces bk_map:^NSValue*(CIFeature* feature) {
                        return [NSValue valueWithCGRect:[image wmf_normalizeAndConvertCGCoordinateRect:feature.bounds]];
                    }];
                    [imageMetadata save];
                    [self setImage:image
                        centeringBounds:imageMetadata.firstFaceBounds
                     forCellAtIndexPath:indexPath
                               animated:shouldAnimate];
                });
            } else {
                [self setImage:image
                    centeringBounds:imageMetadata.firstFaceBounds
                 forCellAtIndexPath:indexPath
                           animated:shouldAnimate];
                return nil;
            }
        }
    });
    return cell;
}

- (void)      setImage:(UIImage*)image
       centeringBounds:(CGRect)normalizedCenterBounds
    forCellAtIndexPath:(NSIndexPath*)path
              animated:(BOOL)animated {
    WMFImageCollectionViewCell* cell = (WMFImageCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:path];
    if (cell) {
        // set contentsRect outside of animation to prevent pan/zoom effect
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        if (CGRectIsEmpty(normalizedCenterBounds)) {
            [cell.imageView wmf_resetContentOffset];
        } else {
            [cell.imageView wmf_setContentOffsetToCenterRect:[image wmf_denormalizeRect:normalizedCenterBounds]];
        }
        [UIView transitionWithView:cell.imageView
                          duration:animated ? [CATransaction animationDuration] : 0.0
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            cell.imageView.image = image;
        } completion:nil];
    }
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    // if there are 0 images, show a placeholder
    return self.images.count > 0 ? self.images.count : 1;
}

@end

NS_ASSUME_NONNULL_END
