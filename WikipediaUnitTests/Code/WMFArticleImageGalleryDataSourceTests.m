//
//  WMFArticleImageGalleryDataSourceTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;

#import "MWKDataStore+TempDataStoreForEach.h"
#import "WMFArticleImageGalleryDataSource.h"
#import "WMFModalArticleImageGalleryDataSource.h"
#import "UIImageView+WMFImageFetchingInternal.h"
#import "MWKImage+AssociationTestUtils.h"
#import "MWKArticle+HTMLImageImport.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

QuickSpecBegin(WMFModalArticleImageGalleryDataSourceTests)

configureTempDataStoreForEach(tempDataStore, ^{});

describe(@"persistence", ^{
    it(@"should load image info from disk", ^{
        MWKTitle* dummyTitle = [MWKTitle random];

        MWKArticle* dummyArticle = [[MWKArticle alloc] initWithTitle:dummyTitle
                                                           dataStore:tempDataStore
                                                                dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

        // populate image list, doesn't happen automatically
        [dummyArticle importAndSaveImagesFromSectionHTML];

        NSArray<MWKImage*>* articleImages = dummyArticle.images.uniqueLargestVariants;

        NSArray<MWKImageInfo*>* info = [articleImages bk_map:^id (MWKImage* img) {
            return [MWKImageInfo infoAssociatedWithSourceURL:img.sourceURLString];
        }];

        expect(info).toNot(beEmpty());

        [tempDataStore saveImageInfo:info forTitle:dummyTitle];

        WMFModalArticleImageGalleryDataSource* modalGalleryDataSource =
            [[WMFModalArticleImageGalleryDataSource alloc] initWithArticle:dummyArticle];

        [info enumerateObjectsUsingBlock:^(MWKImageInfo* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
            expect([modalGalleryDataSource imageInfoAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]])
            .to(equal(obj));
        }];
    });
});

QuickSpecEnd
