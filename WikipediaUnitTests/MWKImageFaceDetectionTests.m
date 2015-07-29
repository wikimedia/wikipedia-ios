//
//  MWKImageFaceDetectionTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKImage.h"

@interface MWKImageFaceDetectionTests : XCTestCase
@property (nonatomic, strong) MWKImage* image;
@property (nonatomic, strong) MWKArticle* dummyArticle;
@end

@implementation MWKImageFaceDetectionTests

- (void)setUp {
    [super setUp];
    self.dummyArticle = [[MWKArticle alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"foo"] dataStore:nil];
}

- (void)testDidNotDetectFacesIsInitiallyFalse {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:@{
                      @"sourceURL": @"foo"
                  }];
    XCTAssertFalse(self.image.didDetectFaces);
}

- (void)testHasFacesIsInitiallyFalse {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:@{
                      @"sourceURL": @"foo"
                  }];
    XCTAssertFalse(self.image.hasFaces);
}

- (void)testHasNoFacesButDidDetectWhenInitializedWithEmptyArray {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:@{
                      @"focalRects": @[],
                      @"sourceURL": @"foo"
                  }];
    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
}

- (void)testHasFacesAndDidDetectWhenInitializedWithNonEmptyArray {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:@{
                      @"focalRects": @[NSStringFromCGRect(CGRectZero)],
                      @"sourceURL": @"foo"
                  }];
    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertTrue(self.image.hasFaces);
}

@end
