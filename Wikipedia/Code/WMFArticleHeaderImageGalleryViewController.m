//
//  WMFHeaderGalleryDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleHeaderImageGalleryViewController.h"
#import "WMFBaseImageGalleryViewController_Subclass.h"

@import Masonry;

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
#import "WMFArticleImageGalleryDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleHeaderImageGalleryViewController ()
@end

@implementation WMFArticleHeaderImageGalleryViewController

+ (UICollectionViewLayout*)headerGalleryLayout {
    UICollectionViewFlowLayout* layout = [WMFCollectionViewPageLayout new];
    layout.scrollDirection         = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0.f;
    layout.minimumLineSpacing      = 0.f;
    layout.sectionInset            = UIEdgeInsetsZero;
    return layout;
}

- (instancetype)init {
    return [super initWithCollectionViewLayout:[[self class] headerGalleryLayout]];
}

- (void)setDataSource:(nullable SSBaseDataSource<WMFImageGalleryDataSource>*)dataSource {
    [super setDataSource:dataSource];
    self.dataSource.cellClass          = [WMFImageCollectionViewCell class];
    self.dataSource.cellConfigureBlock = ^(WMFImageCollectionViewCell* cell,
                                           MWKImage* image,
                                           UICollectionView* _,
                                           NSIndexPath* indexPath)  {
        /*
           Need to use MWKImage here in order to use face detection offsets persisted to disk.
         */
        [cell.imageView wmf_setImageWithMetadata:image detectFaces:YES];
    };
}

- (UIImageView*)imageViewForImage:(MWKImage*)image {
    NSIndexPath* indexPath = [self.dataSource indexPathForItem:image];
    return [self imageViewForIndexPath:indexPath];
}

- (UIImageView*)imageViewForIndexPath:(NSIndexPath*)indexPath {
    WMFImageCollectionViewCell* cell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
    return cell.imageView;
}

- (void)addDivider {
    UIView* divider = [[UIView alloc] initWithFrame:CGRectZero];
    divider.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [self.view addSubview:divider];
    [divider mas_makeConstraints:^(MASConstraintMaker* make) {
        make.bottom.equalTo(self.view.mas_bottom);
        make.leading.equalTo(self.view.mas_leading);
        make.trailing.equalTo(self.view.mas_trailing);
        make.height.equalTo(@0.5);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor           = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self addDivider];

    [self.collectionView registerClass:[WMFImageCollectionViewCell class]
            forCellWithReuseIdentifier:[WMFImageCollectionViewCell wmf_nibName]];
}

#pragma mark - Show Articles

- (WMFArticleImageGalleryDataSource*)articleGalleryDataSource {
    if ([self.dataSource isKindOfClass:[WMFArticleImageGalleryDataSource class]]) {
        return (WMFArticleImageGalleryDataSource*)self.dataSource;
    }
    return nil;
}

- (void)showImagesInArticle:(nullable MWKArticle*)article {
    WMFArticleImageGalleryDataSource* dataSource =
        [[WMFArticleImageGalleryDataSource alloc] initWithArticle:article];
    self.dataSource = (SSBaseDataSource<WMFImageGalleryDataSource>*)dataSource;
    if ([self isViewLoaded]) {
        self.dataSource.collectionView = self.collectionView;
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    [self.delegate headerImageGallery:self didSelectImageAtIndex:indexPath.item];
}

@end

NS_ASSUME_NONNULL_END
