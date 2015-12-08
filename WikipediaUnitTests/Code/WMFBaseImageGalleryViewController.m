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
#import <SSDataSources/SSDataSources.h>

@interface WMFDummyGalleryDataSource : SSArrayDataSource<WMFImageGalleryDataSource>

@end

@implementation WMFDummyGalleryDataSource

- (NSURL*)imageURLAtIndexPath:(NSIndexPath*)indexPath {
    return [NSURL URLWithString:@"http://dummy.net/foo.jpg"];
}

@end


QuickSpecBegin(WMFBaseImageGalleryViewControllerTests)

static WMFBaseImageGalleryViewController * baseGalleryVC;
static WMFDummyGalleryDataSource* dummyDataSource;


beforeEach(^{
    baseGalleryVC = [[WMFBaseImageGalleryViewController alloc] init];
});

afterEach(^{
    dummyDataSource = nil;
});

describe(@"setDataSource:", ^{
    beforeEach(^{
        dummyDataSource = [[WMFDummyGalleryDataSource alloc] initWithItems:@[@0, @1, @2]];
    });

    afterEach(^{
        expect(@(baseGalleryVC.isViewLoaded)).to(beFalse());
    });

    it(@"should keep current page at default (0) in modern LTR environments", ^{
        [baseGalleryVC setDataSource:dummyDataSource
                shouldSetCurrentPage:NO
                     layoutDirection:UIUserInterfaceLayoutDirectionLeftToRight];
        expect(@(baseGalleryVC.currentPage)).to(equal(@0));
    });

    it(@"should keep current page at default (0) in modern RTL environments", ^{
        [baseGalleryVC setDataSource:dummyDataSource
                shouldSetCurrentPage:NO
                     layoutDirection:UIUserInterfaceLayoutDirectionRightToLeft];
        expect(@(baseGalleryVC.currentPage)).to(equal(@0));
    });

    it(@"should keep current page at default (0) in legacy LTR environments", ^{
        [baseGalleryVC setDataSource:dummyDataSource
                shouldSetCurrentPage:YES
                     layoutDirection:UIUserInterfaceLayoutDirectionLeftToRight];
        expect(@(baseGalleryVC.currentPage)).to(equal(@0));
    });

    it(@"should set current page to last element in legacy RTL environments", ^{
        [baseGalleryVC setDataSource:dummyDataSource
                shouldSetCurrentPage:YES
                     layoutDirection:UIUserInterfaceLayoutDirectionRightToLeft];
        expect(@(baseGalleryVC.currentPage)).to(equal(@(dummyDataSource.numberOfItems - 1)));
    });
});

QuickSpecEnd
