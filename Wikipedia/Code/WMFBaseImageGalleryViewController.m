//
//  WMFBaseImageGalleryViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseImageGalleryViewController_Subclass.h"
#import <SSDataSources/SSBaseDataSource.h>
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "SSBaseDataSource+WMFLayoutDirectionUtilities.h"

@implementation WMFBaseImageGalleryViewController

- (void)setDataSource:(SSBaseDataSource<WMFImageGalleryDataSource>*)dataSource {
    if (_dataSource == dataSource) {
        return;
    }
    _dataSource = dataSource;
    // Update current page to last element if on iOS 8 for RTL compliance.
    if (_dataSource && [[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        self.currentPage = [self.dataSource wmf_startingIndexForApplicationLayoutDirection];
    }
    if (self.isViewLoaded) {
        self.collectionView.dataSource = _dataSource;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource.collectionView = self.collectionView;
}

@end
