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

// View
#import "WMFImageCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"

// Model
#import "MWKArticle.h"
#import "MWKImage.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFArticleHeaderImageGalleryViewController

- (void)setImageURLs:(NSArray* __nullable)imageURLs {
    if (WMF_EQUAL(_imageURLs, isEqualToArray:, imageURLs)) {
        return;
    }
    _imageURLs       = [(imageURLs ? : @[]) wmf_reverseArrayIfApplicationIsRTL];
    self.currentPage = [_imageURLs wmf_startingIndexForApplicationLayoutDirection];
    if ([self isViewLoaded]) {
        [self.collectionView reloadData];
    }
}

- (void)setImageURLsFromArticle:(MWKArticle* __nonnull)article {
    if (article.isCached) {
        [self setImageURLsFromCachedArticle:article];
    } else {
        [self setImageURLsFromUncachedArticle:article];
    }
}

- (void)setImageURLsFromCachedArticle:(MWKArticle* __nonnull)article {
    NSParameterAssert(article.isCached);
    self.imageURLs = [article.images.uniqueLargestVariantSourceURLs wmf_reverseArrayIfApplicationIsRTL];
}

- (void)setImageURLsFromUncachedArticle:(MWKArticle* __nonnull)article {
    NSParameterAssert(!article.isCached);
    NSURL* url = [NSURL wmf_optionalURLWithString:article.imageURL];
    if (url) {
        self.imageURLs = [NSMutableArray arrayWithObject:url];
    } else if ((url = [NSURL wmf_optionalURLWithString:article.thumbnailURL])) {
        self.imageURLs = [NSMutableArray arrayWithObject:url];
    } else {
        self.imageURLs = nil;
    }
}

#pragma mark - UICollectionView Protocols

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    [self.delegate headerImageGallery:self didSelectImageAtIndex:indexPath.item];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFImageCollectionViewCell* cell = (WMFImageCollectionViewCell*)
                                       [collectionView dequeueReusableCellWithReuseIdentifier:[WMFImageCollectionViewCell wmf_nibName]
                                                                                 forIndexPath:indexPath];
    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:self.imageURLs[indexPath.item]]
    .then(^(UIImage* image) {
        @strongify(self);
        [self setImage:image forCellAtIndexPath:indexPath];
    });
    return cell;
}

- (void)setImage:(UIImage*)image forCellAtIndexPath:(NSIndexPath*)path {
    WMFImageCollectionViewCell* cell = (WMFImageCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:path];
    if (cell) {
        cell.imageView.image = image;
    }
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageURLs.count;
}

@end

NS_ASSUME_NONNULL_END
