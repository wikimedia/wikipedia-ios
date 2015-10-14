//
//  WebViewController+ImageGalleryPresentation.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WebViewController_Private.h"
#import "WebViewController+ImageGalleryPresentation.h"
#import "WMFImageGalleryViewController.h"
#import "MWKArticle.h"
#import "MWKImageList.h"

@implementation WebViewController (ImageGalleryPresentation)

- (void)presentGalleryForArticle:(MWKArticle*)article showingImage:(MWKImage*)selectedImage {
    if (!self.article.images || self.article.images.count == 0) {
        return;
    }

    WMFImageGalleryViewController* gallery = [[WMFImageGalleryViewController alloc] initWithArticle:article];
    [gallery setVisibleImage:selectedImage animated:NO];
    [self presentViewController:gallery animated:YES completion:nil];
}

@end
