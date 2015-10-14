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
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "CIDetector+WMFFaceDetection.h"

// View
#import "UIImageView+WMFImageFetching.h"
#import "WMFImageCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UIImageView+WMFContentOffset.h"
#import "UIImage+WMFNormalization.h"
#import "WMFCollectionViewPageLayout.h"
#import "UIImage+WMFStyle.h"

// Model
#import "MWKArticle.h"
#import "MWKImage.h"
#import "MWKImageList.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleHeaderImageGalleryViewController ()
@property (nonatomic, strong) CIDetector* faceDetector;
@end

@implementation WMFArticleHeaderImageGalleryViewController

- (instancetype)init {
    return [self initWithCollectionViewLayout:[WMFCollectionViewPageLayout new]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor           = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[WMFImageCollectionViewCell class]
            forCellWithReuseIdentifier:[WMFImageCollectionViewCell wmf_nibName]];
    self.collectionView.pagingEnabled = YES;
    WMFCollectionViewPageLayout* layout = (WMFCollectionViewPageLayout*)self.collectionViewLayout;
    layout.scrollDirection         = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0.f;
    layout.minimumLineSpacing      = 0.f;
    layout.sectionInset            = UIEdgeInsetsZero;
}

#pragma mark - Accessors

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

- (BOOL)collectionView:(UICollectionView*)collectionView shouldSelectItemAtIndexPath:(nonnull NSIndexPath*)indexPath {
    // prevent selection of placeholder image
    return self.images.count > 0;
}

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
        cell.imageView.tintColor = [UIColor wmf_lightGrayColor];
        cell.imageView.image       = [UIImage wmf_placeholderImage];
        cell.imageView.contentMode = UIViewContentModeCenter;
        return cell;
    }

    [cell.imageView wmf_setImageWithMetadata:self.images[indexPath.item] detectFaces:YES];

    return cell;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    // if there are 0 images, show a placeholder
    return self.images.count > 0 ? self.images.count : 1;
}

@end

NS_ASSUME_NONNULL_END
