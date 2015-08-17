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

//#undef LOG_LEVEL_DEF
//#define LOG_LEVEL_DEF DDLogLevelVerbose

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
    if (article.image) {
        self.images = @[article.image];
    } else if (article.thumbnail) {
        self.images = @[article.thumbnail];
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

    // try to set cell's image from memory cache, otherwise fetch it and do face detection if needed
    if (![self setCachedImageForCell:cell atIndexPath:indexPath metadata:imageMetadata]) {
        [self fetchImage:imageMetadata forCellAtIndexPath:indexPath];
    }

    return cell;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    // if there are 0 images, show a placeholder
    return self.images.count > 0 ? self.images.count : 1;
}

#pragma mark - Image Fetching & Setting

/**
 *  Fetch image data for the given `imageMetadata`, and insert it into the cell at the given `indexPath`.
 *
 *  @param imageMetadata    Metadata which specifies where to fetch the image and whether face detection needs to run.
 *  @param indexPath        The `NSIndexPath` for the cell related to the image.
 */
- (void)fetchImage:(MWKImage*)imageMetadata forCellAtIndexPath:(NSIndexPath*)indexPath {
    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:[imageMetadata sourceURL]]
    .then(^id (WMFImageDownload* download) {
        @strongify(self);
        UIImage* image = download.image;
        if (!self) {
            return [NSError cancelledError];
        }
        BOOL shouldAnimate = ![download.origin isEqualToString:[WMFImageDownload imageOriginMemory]];
        if (!imageMetadata.didDetectFaces) {
            DDLogVerbose(@"Running face detection for %@", imageMetadata.sourceURL);
            @weakify(self);
            return [self.faceDetector wmf_detectFeaturelessFacesInImage:image].then(^(NSArray* faces) {
                @strongify(self);
                [imageMetadata setNormalizedFaceBoundsFromFeatures:faces inImage:image];
                [imageMetadata save];
                NSParameterAssert(imageMetadata.didDetectFaces);
                [self setImage:image
                 inCellAtIndexPath:indexPath
                   centeringBounds:imageMetadata.firstFaceBounds
                          animated:shouldAnimate];
            });
        } else {
            DDLogVerbose(@"Setting image %@ after retrieving from %@", imageMetadata.sourceURL, download.origin);
            [self setImage:image
             inCellAtIndexPath:indexPath
               centeringBounds:imageMetadata.firstFaceBounds
                      animated:shouldAnimate];
            return nil;
        }
    })
    .catch(^(NSError* error) {
        // TODO: show error in UI
        DDLogError(@"Failed to fetch image from %@. %@", [imageMetadata sourceURL], error);
    });
}

/**
 *  Attempt to populate the given `cell` with the image for `metadata` if it's stored in memory.
 *
 *  @param cell      The cell to populate.
 *  @param indexPath The indexPath where the cell resides.
 *  @param metadata  The metadata which specifies the image URL and face detection information.
 *
 *  @return `YES` if the image was set from memory, `NO` if a fetch or other processing needs to take place.
 */
- (BOOL)setCachedImageForCell:(WMFImageCollectionViewCell*)cell
                  atIndexPath:(NSIndexPath*)indexPath
                     metadata:(MWKImage*)metadata {
    if (!metadata.didDetectFaces) {
        return NO;
    }
    UIImage* cachedImage = [[WMFImageController sharedInstance] cachedImageInMemoryWithURL:metadata.sourceURL];
    if (!cachedImage) {
        return NO;
    }
    DDLogVerbose(@"%@ was set at indexPath %@ from memory cache.", metadata.sourceURL, indexPath);
    [self setImage:cachedImage
              inCell:cell
     centeringBounds:metadata.firstFaceBounds
            animated:NO];
    return YES;
}

/**
 *  Populate the cell at `indexPath` with the given `image`, if it's visible.
 *
 *  @param image                  The image to set in the cell's image view.
 *  @param indexPath              The indexPath for the cell to update.
 *  @param normalizedCenterBounds The bounds to center in the image view.
 *  @param animated               Whether or not to animate the transition to `image`.
 *
 *  @see setImage:inCell:centeringBounds:animated:
 */
- (void)     setImage:(UIImage*)image
    inCellAtIndexPath:(NSIndexPath*)indexPath
      centeringBounds:(CGRect)normalizedCenterBounds
             animated:(BOOL)animated {
    WMFImageCollectionViewCell* cell = (WMFImageCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
        [self setImage:image inCell:cell centeringBounds:normalizedCenterBounds animated:animated];
    }
}

/**
 *  Populate the given `cell` with `image`, centering the image at `normalizedCenterBounds`.
 *
 *  @param image                  The image to set.
 *  @param cell                   The cell which will be updated.
 *  @param normalizedCenterBounds The focal point to center within the image, normalized to the image's bounds.
 *  @param animated               Whether or not to animate the transition.
 */
- (void)   setImage:(UIImage*)image
             inCell:(WMFImageCollectionViewCell*)cell
    centeringBounds:(CGRect)normalizedCenterBounds
           animated:(BOOL)animated {
    NSParameterAssert(cell);
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

@end

NS_ASSUME_NONNULL_END
