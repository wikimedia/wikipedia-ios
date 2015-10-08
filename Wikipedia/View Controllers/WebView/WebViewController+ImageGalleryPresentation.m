//
//  WebViewController+ImageGalleryPresentation.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFWebViewController_Private.h"
#import "WebViewController+ImageGalleryPresentation.h"
#import "WMFImageGalleryViewController.h"

@implementation WMFWebViewController (ImageGalleryPresentation)

- (void)presentGalleryForArticle:(MWKArticle*)article showingImage:(MWKImage*)selectedImage {
    [self cancelArticleLoading];
    [self cancelSearchLoading];

    if (!self.session.currentArticle.images || self.session.currentArticle.images.count == 0) {
        return;
    }

    WMFImageGalleryViewController* gallery = [[WMFImageGalleryViewController alloc] initWithArticle:article];
    [gallery setVisibleImage:selectedImage animated:NO];
    [self presentViewController:gallery animated:YES completion:nil];
}

@end
