//
//  UIImageView+MWKImageTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFAsyncTestCase.h"
#import "UIImageView+WMFImageFetchingInternal.h"
#import "WMFFaceDetectionCache.h"
#import "Wikipedia-Swift.h"
#import "MWKTitle.h"
#import "MWKArticle.h"
#import "MWKImage.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

@interface UIImageView_MWKImageTests : WMFAsyncTestCase

@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong) MWKArticle* dummyArticle;
@property (nonatomic, strong) WMFImageController* mockImageController;
@property (nonatomic, strong) WMFFaceDetectionCache* faceDetectionCache;

@end

@implementation UIImageView_MWKImageTests

- (void)setUp {
    [super setUp];

    self.imageView = [UIImageView new];

    MWKTitle* dummyTitle = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]];
    self.dummyArticle = [[MWKArticle alloc] initWithTitle:dummyTitle
                                                dataStore:nil];

    self.mockImageController = MKTMock([WMFImageController class]);
    self.faceDetectionCache  = [[WMFFaceDetectionCache alloc] init];
}

- (void)tearDown {
    [super tearDown];
    [[UIImageView faceDetectionCache] clearCache];
}

#pragma mark - Fetch Tests

- (void)testSuccessfullySettingImageFromMetadataWithCenterFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];

    WMFImageDownload* successfulDownload = [[WMFImageDownload alloc] initWithUrl:testURL
                                                                           image:[UIImage new]
                                                                  originRawValue:[WMFImageDownload imageOriginNetwork]];
    [MKTGiven([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:successfulDownload]];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata detectFaces:YES]
    .then(^(){
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    assertThat(self.imageView.image, is(successfulDownload.image));

    assertThat(@(testMetadata.didDetectFaces), isTrue());

    XCTAssert([[UIImageView faceDetectionCache] imageRequiresFaceDetection:testMetadata] == NO,
              @"Face detection should have ran.");

    [MKTVerify(self.mockImageController) fetchImageWithURL:testURL];
}

- (void)testSuccessfullySettingImageFromURLWithCenterFaces {
    NSURL* testURL                       = [NSURL URLWithString:@"http://test/request.png"];
    WMFImageDownload* successfulDownload = [[WMFImageDownload alloc] initWithUrl:testURL
                                                                           image:[UIImage new]
                                                                  originRawValue:[WMFImageDownload imageOriginNetwork]];
    [MKTGiven([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:successfulDownload]];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:testURL detectFaces:YES]
    .then(^(){
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageURL == testURL,
              @"Image url should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    assertThat(self.imageView.image, is(successfulDownload.image));

    XCTAssert([[UIImageView faceDetectionCache] imageAtURLRequiresFaceDetection:testURL] == NO,
              @"Face detection should have ran.");

    [MKTVerify(self.mockImageController) fetchImageWithURL:testURL];
}

- (void)testSuccessfullySettingImageFromMetadataWithoutCenterFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];

    WMFImageDownload* successfulDownload = [[WMFImageDownload alloc] initWithUrl:testURL
                                                                           image:[UIImage new]
                                                                  originRawValue:[WMFImageDownload imageOriginNetwork]];
    [MKTGiven([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:successfulDownload]];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata detectFaces:NO]
    .then(^(){
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");


    [MKTVerify(self.mockImageController) fetchImageWithURL:testURL];

    WaitForExpectations();

    assertThat(self.imageView.image, is(successfulDownload.image));

    XCTAssert([[UIImageView faceDetectionCache] imageRequiresFaceDetection:testMetadata],
              @"Face detection should NOT have ran.");

    assertThat(@(testMetadata.didDetectFaces), isFalse());
}

- (void)testSuccessfullySettingImageFromURLWithoutCenterFaces {
    NSURL* testURL                       = [NSURL URLWithString:@"http://test/request.png"];
    WMFImageDownload* successfulDownload = [[WMFImageDownload alloc] initWithUrl:testURL
                                                                           image:[UIImage new]
                                                                  originRawValue:[WMFImageDownload imageOriginNetwork]];
    [MKTGiven([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:successfulDownload]];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:testURL detectFaces:NO]
    .then(^(){
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageURL == testURL,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    assertThat(self.imageView.image, is(successfulDownload.image));

    XCTAssert([[UIImageView faceDetectionCache] imageAtURLRequiresFaceDetection:testURL],
              @"Face detection should NOT have ran.");

    [MKTVerify(self.mockImageController) fetchImageWithURL:testURL];
}

- (void)testSuccessfullySettingCachedImageWithoutCenterFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    UIImage* testImage     = [UIImage new];

    [MKTGiven([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata detectFaces:NO]
    .then(^(){
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    assertThat(self.imageView.image, is(testImage));

    XCTAssert([[UIImageView faceDetectionCache] imageRequiresFaceDetection:testMetadata],
              @"Face detection should NOT have ran.");

    [MKTVerifyCount(self.mockImageController, MKTNever()) fetchImageWithURL:testURL];
}

- (void)testSuccessfullySettingCachedImageURLWithoutCenterFaces {
    NSURL* testURL     = [NSURL URLWithString:@"http://test/request.png"];
    UIImage* testImage = [UIImage new];

    [MKTGiven([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:testURL detectFaces:NO]
    .then(^(){
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageURL == testURL,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    assertThat(self.imageView.image, is(testImage));

    XCTAssert([[UIImageView faceDetectionCache] imageAtURLRequiresFaceDetection:testURL],
              @"Face detection should NOT have ran.");

    [MKTVerifyCount(self.mockImageController, MKTNever()) fetchImageWithURL:testURL];
}

- (void)testSuccessfullySettingCachedImageWithCenterFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    testMetadata.allNormalizedFaceBounds = @[];
    UIImage* testImage = [UIImage new];

    [MKTGiven([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata detectFaces:YES]
    .then(^(){
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    assertThat(self.imageView.image, is(testImage));

    XCTAssert([[UIImageView faceDetectionCache] imageRequiresFaceDetection:testMetadata] == NO,
              @"Face detection should have ran.");

    [MKTVerifyCount(self.mockImageController, MKTNever()) fetchImageWithURL:testURL];
}

- (void)testSuccessfullySettingCachedImageURLWithCenterFaces {
    NSURL* testURL     = [NSURL URLWithString:@"http://test/request.png"];
    UIImage* testImage = [UIImage new];

    [MKTGiven([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:testURL detectFaces:YES]
    .then(^(){
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageURL == testURL,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    assertThat(self.imageView.image, is(testImage));

    XCTAssert([[UIImageView faceDetectionCache] imageAtURLRequiresFaceDetection:testURL] == NO,
              @"Face detection should have ran.");

    [MKTVerifyCount(self.mockImageController, MKTNever()) fetchImageWithURL:testURL];
}

- (void)testFailureToSetUncachedImageWithFetchError {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    NSError* testError     = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil];

    [MKTGiven([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:nil];
    [MKTGiven([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:testError]];

    self.imageView.wmf_imageController = self.mockImageController;

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata detectFaces:YES]
    .then(^(){
        XCTFail(@"Promise fullfilled erroneously with url %@", [testURL description]);
    })
    .catch(^(NSError* error){
        [promiseExpectation fulfill];
    });

    WaitForExpectations();
}

- (void)testFailureToSetUncachedImageURLWithFetchError {
    NSURL* testURL     = [NSURL URLWithString:@"http://test/request.png"];
    NSError* testError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil];

    [MKTGiven([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:nil];
    [MKTGiven([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:testError]];

    self.imageView.wmf_imageController = self.mockImageController;

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:testURL detectFaces:YES]
    .then(^(){
        XCTFail(@"Promise fullfilled erroneously with url %@", [testURL description]);
    })
    .catch(^(NSError* error){
        XCTAssert([error domain] == NSURLErrorDomain && [error code] == NSURLErrorCannotConnectToHost,
                  @"Error shoudl be the one passed to the mock");
        [promiseExpectation fulfill];
    });

    WaitForExpectations();
}

- (void)testShouldNotFetchCachedImage {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    UIImage* testImage     = [UIImage new];

    [MKTGiven([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata detectFaces:NO]
    .then(^(){
        assertThat(self.imageView.image, is(testImage));
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    WaitForExpectations();

    [MKTVerifyCount(self.mockImageController, MKTNever()) fetchImageWithURL:anything()];
}

- (void)testShouldNotFetchCachedImageURL {
    NSURL* testURL     = [NSURL URLWithString:@"http://test/request.png"];
    UIImage* testImage = [UIImage new];

    [MKTGiven([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    [self.imageView wmf_setImageController:self.mockImageController];

    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:testURL detectFaces:NO]
    .then(^(){
        assertThat(self.imageView.image, is(testImage));
        [promiseExpectation fulfill];
    })
    .catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });

    WaitForExpectations();

    [MKTVerifyCount(self.mockImageController, MKTNever()) fetchImageWithURL:anything()];
}

- (void)testFailureOfImageCacheToDetectFacesOfImageWithNoFaces {
    NSURL* testURL                        = [NSURL URLWithString:@"http://test/request.png"];
    XCTestExpectation* promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.faceDetectionCache detectFaceBoundsInImage:[UIImage new] URL:testURL]
    .then(^(NSValue* bounds){
        XCTAssert(CGRectIsEmpty([bounds CGRectValue]), @"Bounds should be null since the image has no data");
        [promiseExpectation fulfill];
    });

    WaitForExpectations();

    assertThat(@([self.faceDetectionCache imageAtURLRequiresFaceDetection:testURL]), isFalse());
    assertThat([self.faceDetectionCache faceBoundsForURL:testURL], nilValue());
}

@end
