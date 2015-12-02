//
//  WMFModalArticleImageGalleryViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFModalArticleImageGalleryViewController.h"
#import "WMFModalImageGalleryViewController_Subclass.h"
#import "WMFBaseImageGalleryViewController_Subclass.h"
#import "MWKArticle.h"
#import "MWKImage.h"
#import "WMFModalArticleImageGalleryDataSource.h"
#import "UIViewController+Alert.h"

@interface WMFModalArticleImageGalleryViewController ()

@property (nonatomic, weak) PMKResolver articlePromiseResolve;

@end

@implementation WMFModalArticleImageGalleryViewController

#pragma mark - Article APIs

- (WMFModalArticleImageGalleryDataSource*)articleGalleryDataSource {
    NSParameterAssert(!self.dataSource || [self.dataSource isKindOfClass:[WMFModalArticleImageGalleryDataSource class]]);
    return (WMFModalArticleImageGalleryDataSource*)self.dataSource;
}

- (void)setVisibleImage:(MWKImage*)visibleImage animated:(BOOL)animated {
    NSInteger selectedImageIndex = [self.articleGalleryDataSource.allItems indexOfObjectPassingTest:^BOOL (MWKImage* image,
                                                                                                           NSUInteger idx,
                                                                                                           BOOL* stop) {
        if ([image isEqualToImage:visibleImage] || [image isVariantOfImage:visibleImage]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (selectedImageIndex == NSNotFound) {
        DDLogWarn(@"Falling back to showing the first image.");
        selectedImageIndex = 0;
    }

    self.currentPage = selectedImageIndex;
}

- (void)showImagesInArticle:(MWKArticle* __nullable)article {
    if (WMF_EQUAL(self.articleGalleryDataSource.article, isEqualToArticle:, article)) {
        return;
    }

    WMFModalArticleImageGalleryDataSource* articleGalleryDataSource = [[WMFModalArticleImageGalleryDataSource alloc] initWithItems:nil];
    articleGalleryDataSource.article = article;

    self.dataSource = articleGalleryDataSource;
}

- (void)setArticleWithPromise:(AnyPromise*)articlePromise {
    if (self.articlePromiseResolve) {
        self.articlePromiseResolve([NSError cancelledError]);
    }

    [self.loadingIndicator startAnimating];

    __block id articlePromiseResolve;
    // wrap articlePromise in a promise we can cancel if a new one comes in
    AnyPromise* cancellableArticlePromise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        articlePromiseResolve = resolve;
    }];
    self.articlePromiseResolve = articlePromiseResolve;

    articlePromise.then(articlePromiseResolve).catchWithPolicy(PMKCatchPolicyAllErrors, articlePromiseResolve);

    // chain off the cancellable promise
    @weakify(self);
    cancellableArticlePromise.then(^(MWKArticle* article) {
        @strongify(self);
        [self showImagesInArticle:article];
    })
    .catch(^(NSError* error) {
        @strongify(self);
        [self.loadingIndicator stopAnimating];
        [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:2.f];
    });
}

@end
