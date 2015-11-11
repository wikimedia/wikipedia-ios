//
//  WMFBaseImageGalleryViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseImageGalleryViewController_Subclass.h"
#import "WMFImageGalleryDataSource.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"

@interface WMFBaseImageGalleryViewController ()
@end

@implementation WMFBaseImageGalleryViewController
@synthesize dataSource = _dataSource;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout*)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        _dataSource = [[WMFImageGalleryDataSource alloc] initWithItems:nil];
    }
    return self;
}

- (void)showImagesInArticle:(MWKArticle*)article {
    self.dataSource.article = article;
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        self.currentPage = [[self.dataSource allItems] wmf_startingIndexForApplicationLayoutDirection];
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource.collectionView = self.collectionView;
}

@end
