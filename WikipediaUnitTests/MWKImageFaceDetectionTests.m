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
#import "WMFTestFixtureUtilities.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKImageFaceDetectionTests : XCTestCase
@property (nonatomic, strong) MWKImage* image;
@property (nonatomic, strong) MWKArticle* dummyArticle;
@property (nonatomic, strong) MWKDataStore* mockDataStore;
@end

@implementation MWKImageFaceDetectionTests

- (void)setUp {
    [super setUp];
    self.mockDataStore = mock([MWKDataStore class]);
    self.dummyArticle  = [[MWKArticle alloc] initWithTitle:[[MWKSite siteWithCurrentLocale] titleWithString:@"foo"]
                                                 dataStore:self.mockDataStore];
}

#pragma mark - Serialization

- (void)testInitialStateShouldIndicateNoDetectionOrFaces {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:@"foo"];
    XCTAssertFalse(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
    XCTAssertNil(self.image.focalRectsInUnitCoordinatesAsStrings);
}

- (void)testSerializationOfImageWithoutDetection {
    NSString* sourceURL    = @"foo";
    NSDictionary* testData = NSDictionaryOfVariableBindings(sourceURL);
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:testData];
    assertThat(self.image.sourceURL, is(sourceURL));
    XCTAssertFalse(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
    assertThat([self.image dataExport], is(testData));
}

- (void)testDeserializedImageWithDetectionButNoFaces {
    NSDictionary* testData = @{
        @"focalRects": @[],
        @"sourceURL": @"foo"
    };
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:testData];
    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
    assertThat(self.image.focalRectsInUnitCoordinatesAsStrings, isEmpty());
    assertThat([self.image dataExport], is(equalTo(testData)));
}

- (void)testDeserializedImageWithDetectedFaces {
    NSDictionary* testData = @{
        @"focalRects": @[NSStringFromCGRect(CGRectMake(1, 1, 10, 10))],
        @"sourceURL": @"foo"
    };
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:testData];
    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertTrue(self.image.hasFaces);
    assertThat(self.image.focalRectsInUnitCoordinatesAsStrings, is(equalTo(testData[@"focalRects"])));
    assertThat(NSStringFromCGRect([self.image primaryFocalRectNormalizedToImageSize:NO]),
               is(equalTo([testData[@"focalRects"] firstObject])));
    assertThat([self.image dataExport], is(equalTo(testData)));
}

#pragma mark - Detection

- (void)testDetectingFacesInFacelessImage {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:@"foo"];

    UIImage* facelessImage = [UIImage imageNamed:@"golden-gate.jpg"
                                        inBundle:[self wmf_bundle]
                   compatibleWithTraitCollection:nil];
    NSParameterAssert(facelessImage);

    [given([self.mockDataStore imageDataWithImage:self.image]) willReturn:UIImageJPEGRepresentation(facelessImage, 1.0)];

    [self.image calculateFocalRectsBasedOnFaceDetectionWithImageData:nil];

    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
}

- (void)testDetectingFacesInObamaLeadImage {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:@"foo"];

    UIImage* facelessImage = [UIImage imageNamed:@"640px-President_Barack_Obama.jpg"
                                        inBundle:[self wmf_bundle]
                   compatibleWithTraitCollection:nil];
    NSParameterAssert(facelessImage);

    [given([self.mockDataStore imageDataWithImage:self.image]) willReturn:UIImageJPEGRepresentation(facelessImage, 1.0)];

    [self.image calculateFocalRectsBasedOnFaceDetectionWithImageData:nil];

    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertTrue(self.image.hasFaces);
    XCTAssertEqualObjects(self.image.focalRectsInUnitCoordinatesAsStrings,
                          @[@"{{0.34843750000000001, 0.09637046307884857}, {0.28750000000000003, 0.230287859824781}}"]);
}

@end
