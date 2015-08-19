//
//  MWKImageFaceDetectionTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKImage+FaceDetection.h"
#import "WMFTestFixtureUtilities.h"
#import "CIDetector+WMFFaceDetection.h"
#import "WMFAsyncTestCase.h"
#import "XCTestCase+PromiseKit.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKImageFaceDetectionTests : WMFAsyncTestCase
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
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:[NSURL URLWithString:@"foo"]];
    XCTAssertFalse(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
    XCTAssertNil(self.image.allNormalizedFaceBounds);
}

- (void)testSerializationOfImageWithoutDetection {
    NSString* sourceURL    = @"foo";
    NSDictionary* testData = NSDictionaryOfVariableBindings(sourceURL);
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:testData];
    assertThat(self.image.sourceURLString, is(sourceURL));
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
    assertThat(self.image.allNormalizedFaceBounds, isEmpty());
    assertThat([self.image dataExport], is(equalTo(testData)));
}

- (void)testDeserializedImageWithDetectedFaces {
    CGRect testRect        = CGRectMake(1, 1, 10, 10);
    NSDictionary* testData = @{
        @"focalRects": @[NSStringFromCGRect(testRect)],
        @"sourceURL": @"foo"
    };
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:testData];
    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertTrue(self.image.hasFaces);
    assertThat(self.image.allNormalizedFaceBounds, is(equalTo(@[[NSValue valueWithCGRect:testRect]])));
    XCTAssertTrue(CGRectEqualToRect(self.image.firstFaceBounds, testRect));
    assertThat([self.image dataExport], is(equalTo(testData)));
}

#pragma mark - Detection

- (void)testDetectingFacesInFacelessImage {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:[NSURL URLWithString:@"foo"]];

    UIImage* facelessImage = [UIImage imageNamed:@"golden-gate.jpg"
                                        inBundle:[self wmf_bundle]
                   compatibleWithTraitCollection:nil];
    NSParameterAssert(facelessImage);

    [self expectAnyPromiseToResolve:^AnyPromise*{
        CIDetector* sharedDetector = [CIDetector wmf_sharedLowAccuracyBackgroundFaceDetector];
        return [sharedDetector wmf_detectFeaturelessFacesInImage:facelessImage]
        .then(^(NSArray* faces) {
            [self.image setNormalizedFaceBoundsFromFeatures:faces inImage:facelessImage];
        });
    } timeout:WMFDefaultExpectationTimeout * 2 WMFExpectFromHere];

    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
}

- (void)testDetectingFacesInEmptyImage {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:[NSURL URLWithString:@"foo"]];

    UIImage* emptyImage = [UIImage new];
    NSParameterAssert(emptyImage);

    [self expectAnyPromiseToResolve:^AnyPromise*{
        CIDetector* sharedDetector = [CIDetector wmf_sharedLowAccuracyBackgroundFaceDetector];
        return [sharedDetector wmf_detectFeaturelessFacesInImage:emptyImage]
        .then(^(NSArray* faces) {
            [self.image setNormalizedFaceBoundsFromFeatures:faces inImage:emptyImage];
        });
    } timeout:WMFDefaultExpectationTimeout WMFExpectFromHere];

    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
}

- (void)testShouldSetDidDetectFacesIfPassedNilFeatures {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:[NSURL URLWithString:@"foo"]];
    [self.image setNormalizedFaceBoundsFromFeatures:nil inImage:nil];
    XCTAssertTrue(self.image.didDetectFaces, @"Need to be able to handle cases where CIDetector passes nil.");
}

// TODO: visual test for centered UIImageView
#if 0
- (void)testDetectingFacesInObamaLeadImage {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:[NSURL URLWithString:@"foo"]];

    UIImage* imageWithFaces = [UIImage imageNamed:@"640px-President_Barack_Obama.jpg"
                                         inBundle:[self wmf_bundle]
                    compatibleWithTraitCollection:nil];
    NSParameterAssert(imageWithFaces);

    [self expectAnyPromiseToResolve:^AnyPromise*{
        CIDetector* sharedDetector = [CIDetector wmf_sharedLowAccuracyBackgroundFaceDetector];
        return [sharedDetector wmf_detectFeaturelessFacesInImage:imageWithFaces]
        .then(^(NSArray* faces) {
            [self.image setNormalizedFaceBoundsFromFeatures:faces inImage:imageWithFaces];
        });
    } timeout:WMFDefaultExpectationTimeout WMFExpectFromHere];

    XCTAssertTrue(self.image.didDetectFaces);
    XCTAssertTrue(self.image.hasFaces);
}

#endif

@end
