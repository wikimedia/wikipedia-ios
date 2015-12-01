//
//  WMFArticleImageGalleryViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleImageGalleryViewController.h"
#import "WMFBaseImageGalleryViewController_Subclass.h"
#import "MWKArticle.h"
#import "WMFImageGalleryDataSource.h"


@implementation WMFArticleImageGalleryViewController

- (WMFImageGalleryDataSource*)articleGalleryDataSource {
    NSParameterAssert(!self.dataSource || [self.dataSource isKindOfClass:[WMFImageGalleryDataSource class]]);
    return (WMFImageGalleryDataSource*)self.dataSource;
}

- (void)showImagesInArticle:(MWKArticle*)article {
    WMFImageGalleryDataSource* dataSource = [[WMFImageGalleryDataSource alloc] initWithItems:nil];
    dataSource.article = article;
    self.dataSource = (SSBaseDataSource*)dataSource;
    if ([self isViewLoaded]) {
        self.dataSource.collectionView = self.collectionView;
    }
}

@end
