//
//  WMFBaseImageGalleryViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseImageGalleryViewController_Testing.h"
#import <SSDataSources/SSBaseDataSource.h>
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "SSBaseDataSource+WMFLayoutDirectionUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFBaseImageGalleryViewController

- (void)setDataSource:(nullable SSBaseDataSource<WMFImageGalleryDataSource>*)dataSource {
    [self setDataSource:dataSource
     shouldSetCurrentPage:[[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]
          layoutDirection:[[UIApplication sharedApplication] userInterfaceLayoutDirection]];
}

- (void)   setDataSource:(nullable SSBaseDataSource<WMFImageGalleryDataSource>*)dataSource
    shouldSetCurrentPage:(BOOL)shouldSetCurrentPage
         layoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection {
    if (_dataSource == dataSource) {
        return;
    }

    _dataSource = dataSource;

    // NOTE(bgerstle): set this first so we can verify currentPage bounds immediately if possible (on iOS 8)
    if (self.isViewLoaded) {
        self.collectionView.dataSource = _dataSource;
    }

    // Update current page to last element if on iOS 8 for RTL compliance.
    if (_dataSource && shouldSetCurrentPage) {
        self.currentPage = [self.dataSource wmf_startingIndexForLayoutDirection:layoutDirection];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource.collectionView = self.collectionView;
}

@end

NS_ASSUME_NONNULL_END
