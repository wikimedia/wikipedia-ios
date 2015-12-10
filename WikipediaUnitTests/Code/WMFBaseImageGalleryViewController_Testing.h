//
//  WMFBaseImageGalleryViewController_Testing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/8/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseImageGalleryViewController_Subclass.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFBaseImageGalleryViewController ()

- (void)   setDataSource:(nullable SSBaseDataSource<WMFImageGalleryDataSource>*)dataSource
    shouldSetCurrentPage:(BOOL)shouldSetCurrentPage
         layoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection;

@end

NS_ASSUME_NONNULL_END
