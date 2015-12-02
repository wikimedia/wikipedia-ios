//
//  WMFImageGalleryViewController_Subclass.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageGalleryViewController.h"
#import "WMFModalArticleImageGalleryDataSource.h"

@class WMFGradientView;

@interface WMFImageGalleryViewController ()
<UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, WMFModalImageGalleryDataSourceDelegate>

@property (nonatomic, weak, readonly) UICollectionViewFlowLayout* collectionViewFlowLayout;
@property (nonatomic, weak, readonly) UIButton* closeButton;
@property (nonatomic, weak, readonly) WMFGradientView* topGradientView;

@property (nonatomic, weak, readonly) UITapGestureRecognizer* chromeTapGestureRecognizer;

@property (nonatomic, weak) UIActivityIndicatorView* loadingIndicator;

@end
