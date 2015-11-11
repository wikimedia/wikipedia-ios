//
//  WMFHeaderGalleryDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleHeaderImageGalleryViewController.h"
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
#import "WMFImageGalleryDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleHeaderImageGalleryViewController ()
@property (nonatomic, strong) CIDetector* faceDetector;
@property (nonatomic, strong, readwrite) WMFImageGalleryDataSource* dataSource;
@end

@implementation WMFArticleHeaderImageGalleryViewController

- (instancetype)init {
    return [self initWithCollectionViewLayout:[WMFCollectionViewPageLayout new]];
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

    WMFCollectionViewPageLayout* layout = (WMFCollectionViewPageLayout*)self.collectionViewLayout;
    layout.scrollDirection         = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0.f;
    layout.minimumLineSpacing      = 0.f;
    layout.sectionInset            = UIEdgeInsetsZero;

    self.dataSource.collectionView = self.collectionView;
}

#pragma mark - Accessors

- (WMFImageGalleryDataSource*)dataSource {
    if (!_dataSource) {
        _dataSource                    = [[WMFImageGalleryDataSource alloc] initWithItems:nil];
        _dataSource.cellClass          = [WMFImageCollectionViewCell class];
        _dataSource.cellConfigureBlock = ^(WMFImageCollectionViewCell* cell,
                                           MWKImage* image,
                                           UICollectionView* _,
                                           NSIndexPath* indexPath)  {
            [cell.imageView wmf_setImageWithMetadata:image detectFaces:YES];
        };
    }
    return _dataSource;
}

- (CIDetector*)faceDetector {
    if (!_faceDetector) {
        _faceDetector = [CIDetector wmf_sharedLowAccuracyBackgroundFaceDetector];
    }
    return _faceDetector;
}

- (void)setImagesFromArticle:(MWKArticle*)article {
    self.dataSource.article = article;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    [self.delegate headerImageGallery:self didSelectImageAtIndex:indexPath.item];
}

@end

NS_ASSUME_NONNULL_END
