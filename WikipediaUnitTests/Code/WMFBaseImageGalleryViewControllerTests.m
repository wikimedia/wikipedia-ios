//
//  WMFBaseImageGalleryViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/8/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;

#import "WMFBaseImageGalleryViewController_Testing.h"
#import "WMFCollectionViewPageLayout.h"
#import <SSDataSources/SSDataSources.h>

@interface WMFDummyGalleryDataSource : SSArrayDataSource<WMFImageGalleryDataSource>

@end

@implementation WMFDummyGalleryDataSource

- (NSURL*)imageURLAtIndexPath:(NSIndexPath*)indexPath {
    return [NSURL URLWithString:@"http://dummy.net/foo.jpg"];
}

@end

QuickSpecBegin(WMFBaseImageGalleryViewControllerTests)

describe(@"setDataSource:", ^{
    __block WMFBaseImageGalleryViewController* baseGalleryVC;
    __block WMFDummyGalleryDataSource* dummyDataSource;

    beforeEach(^{
        baseGalleryVC = [[WMFBaseImageGalleryViewController alloc] initWithCollectionViewLayout:[WMFCollectionViewPageLayout new]];
        dummyDataSource = [[WMFDummyGalleryDataSource alloc] initWithItems:@[@0, @1, @2]];
    });

    context(@"before its view is loaded", ^{
        afterEach(^{
            expect(@(baseGalleryVC.isViewLoaded))
            .toWithDescription(beFalse(), @"Setting the data source shouldn't cause the view to load.");
        });

        itBehavesLike(@"an RTL compliant gallery", ^{
            return @{ @"gallery": baseGalleryVC,
                      @"dataSource": dummyDataSource };
        });
    });

    context(@"after its view is loaded", ^{
        beforeEach(^{
            [baseGalleryVC view];
        });

        itBehavesLike(@"an RTL compliant gallery", ^{
            return @{ @"gallery": baseGalleryVC,
                      @"dataSource": dummyDataSource };
        });
    });
});

QuickSpecEnd

QuickConfigurationBegin(WMFBaseImageGalleryViewControllerTestsConfig)

+ (void)configure : (Configuration*)configuration {
    sharedExamples(@"an RTL compliant gallery", ^(QCKDSLSharedExampleContext exampleContextProvider) {
        __block WMFBaseImageGalleryViewController* gallery;
        __block SSBaseDataSource<WMFImageGalleryDataSource>* dataSource;

        beforeEach(^{
            NSDictionary* exampleContext = exampleContextProvider();
            gallery = exampleContext[@"gallery"];
            dataSource = exampleContext[@"dataSource"];
        });

        it(@"should keep current page at default (0) in modern LTR environments", ^{
            [gallery setDataSource:dataSource
              shouldSetCurrentPage:NO
                   layoutDirection:UIUserInterfaceLayoutDirectionLeftToRight];
            expect(@(gallery.currentPage)).to(equal(@0));
        });

        it(@"should keep current page at default (0) in modern RTL environments", ^{
            NSDictionary* exampleContext = exampleContextProvider();
            WMFBaseImageGalleryViewController* gallery = exampleContext[@"gallery"];
            SSBaseDataSource<WMFImageGalleryDataSource>* dataSource = exampleContext[@"dataSource"];

            [gallery setDataSource:dataSource
              shouldSetCurrentPage:NO
                   layoutDirection:UIUserInterfaceLayoutDirectionRightToLeft];
            expect(@(gallery.currentPage)).to(equal(@0));
        });

        it(@"should keep current page at default (0) in legacy LTR environments", ^{
            NSDictionary* exampleContext = exampleContextProvider();
            WMFBaseImageGalleryViewController* gallery = exampleContext[@"gallery"];
            SSBaseDataSource<WMFImageGalleryDataSource>* dataSource = exampleContext[@"dataSource"];

            [gallery setDataSource:dataSource
              shouldSetCurrentPage:YES
                   layoutDirection:UIUserInterfaceLayoutDirectionLeftToRight];
            expect(@(gallery.currentPage)).to(equal(@0));
        });

        it(@"should set current page to last element in legacy RTL environments", ^{
            [gallery setDataSource:dataSource
              shouldSetCurrentPage:YES
                   layoutDirection:UIUserInterfaceLayoutDirectionRightToLeft];
            expect(@(gallery.currentPage)).to(equal(@(dataSource.numberOfItems - 1)));
        });
    });
}

QuickConfigurationEnd
