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

@implementation WebViewController (ImageGalleryPresentation)

- (void)presentGalleryForArticle:(MWKArticle*)article showingImage:(MWKImage*)selectedImage
{
    [self cancelArticleLoading];
    [self cancelSearchLoading];

    NSArray *images = [session.article.images uniqueLargestVariants];

    // !!!: hack until we fix race condition between images loading and tap
    if (!images || images.count == 0) { return; }

    NSInteger selectedImageIndex =
        [images indexOfObjectPassingTest:
         ^BOOL(MWKImage *image, NSUInteger idx, BOOL *stop) {
             if ([image isEqualToImage:selectedImage] || [image isVariantOfImage:selectedImage]) {
                 *stop = YES;
                 return YES;
             }
             return NO;
         }];

    if (selectedImageIndex == NSNotFound) {
        NSLog(@"WARNING: falling back to showing the first image.");
        selectedImageIndex = 0;
    }

    WMFImageGalleryViewController *gallery =
        [[WMFImageGalleryViewController alloc] initWithArticle:article];
    gallery.visibleImageIndex = selectedImageIndex;
    [self presentViewController:gallery animated:YES completion:nil];
}

@end
