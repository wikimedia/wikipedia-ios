//
//  UIImageView+MWKImageTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFAsyncTestCase.h"
#import "UIImageView+MWKImageInternal.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

@interface UIImageView_MWKImageTests : WMFAsyncTestCase

@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong) MWKArticle* dummyArticle;
@property (nonatomic, strong) WMFImageController* mockImageController;

@end

@implementation UIImageView_MWKImageTests

- (void)setUp {
    [super setUp];

    self.imageView = [UIImageView new];

    MWKTitle* dummyTitle = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]];
    self.dummyArticle = [[MWKArticle alloc] initWithTitle:dummyTitle
                                                dataStore:nil];

    self.mockImageController = mock([WMFImageController class]);
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Logic Tests

- (void)testShouldNotAnimateWhenNeverAnimateIsSet {
    assertThat(@(WMFApplyImageOptionsToAnimationFlag(WMFImageOptionNeverAnimate, YES)), isFalse());
    assertThat(@(WMFApplyImageOptionsToAnimationFlag(WMFImageOptionNeverAnimate, NO)), isFalse());
}

- (void)testShouldAnimateWhenAlwaysAnimateIsSet {
    assertThat(@(WMFApplyImageOptionsToAnimationFlag(WMFImageOptionAlwaysAnimate, YES)), isTrue());
    assertThat(@(WMFApplyImageOptionsToAnimationFlag(WMFImageOptionAlwaysAnimate, NO)), isTrue());
}

- (void)testShouldReturnGivenAnimationFlagIfNoOptionsSet {
    assertThat(@(WMFApplyImageOptionsToAnimationFlag(0, YES)), isTrue());
    assertThat(@(WMFApplyImageOptionsToAnimationFlag(0, NO)), isFalse());
}

- (void)testShouldDetectFacesIfOptionIsSetAndImageDidNotDetectFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    XCTAssertTrue(WMFShouldDetectFacesForMetadataWithOptions(testMetadata, WMFImageOptionCenterFace));
}

- (void)testShouldNotDetectFacesIfOptionIsSetAndImageDidDetectFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    testMetadata.allNormalizedFaceBounds = @[];
    XCTAssertFalse(WMFShouldDetectFacesForMetadataWithOptions(testMetadata, WMFImageOptionCenterFace));
}

- (void)testShouldNotDetectFacesIfOptionIsNotSet {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    XCTAssertFalse(WMFShouldDetectFacesForMetadataWithOptions(testMetadata, 0));
    testMetadata.allNormalizedFaceBounds = @[];
    XCTAssertFalse(WMFShouldDetectFacesForMetadataWithOptions(testMetadata, 0));
}

#pragma mark - Fetch Tests

- (void)testSuccessfullySettingImageFromMetadataWithCenterFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];

    WMFImageDownload* successfulDownload = [[WMFImageDownload alloc] initWithUrl:testURL
                                                                           image:[UIImage new]
                                                                          origin:[WMFImageDownload imageOriginNetwork]];
    [given([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:successfulDownload]];

    XCTestExpectation* completionExpectation    = [self expectationWithDescription:@"completion block was called"];
    XCTestExpectation* setImageBlockExpectation = [self expectationWithDescription:@"setImageBlock was called"];
    [self.imageView
     wmf_setImageFromMetadata:testMetadata
                      options:WMFImageOptionCenterFace
                    withBlock:^(UIImageView* imgView, UIImage* img, MWKImage* meta) {
        assertThat(imgView, is(self.imageView));
        assertThat(img, is(successfulDownload.image));
        assertThat(meta, is(testMetadata));
        [setImageBlockExpectation fulfill];
    }
                   completion:^(BOOL finished) { [completionExpectation fulfill]; }
                      onError:^(NSError* err) { XCTFail(@"Error callback erroneously called with error %@", err); }
              usingController:self.mockImageController];

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    [MKTVerify(self.mockImageController) fetchImageWithURL:testURL];

    WaitForExpectations();

    assertThat(@(testMetadata.didDetectFaces), isTrue());
}

- (void)testSuccessfullySettingImageFromMetadataWithoutCenterFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];

    WMFImageDownload* successfulDownload = [[WMFImageDownload alloc] initWithUrl:testURL
                                                                           image:[UIImage new]
                                                                          origin:[WMFImageDownload imageOriginNetwork]];
    [given([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:successfulDownload]];

    XCTestExpectation* completionExpectation    = [self expectationWithDescription:@"completion block was called"];
    XCTestExpectation* setImageBlockExpectation = [self expectationWithDescription:@"setImageBlock was called"];
    [self.imageView
     wmf_setImageFromMetadata:testMetadata
                      options:0
                    withBlock:^(UIImageView* imgView, UIImage* img, MWKImage* meta) {
        assertThat(imgView, is(self.imageView));
        assertThat(img, is(successfulDownload.image));
        assertThat(meta, is(testMetadata));
        [setImageBlockExpectation fulfill];
    }
                   completion:^(BOOL finished) { [completionExpectation fulfill]; }
                      onError:^(NSError* err) { XCTFail(@"Error callback erroneously called with error %@", err); }
              usingController:self.mockImageController];

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    [MKTVerify(self.mockImageController) fetchImageWithURL:testURL];

    WaitForExpectations();

    assertThat(@(testMetadata.didDetectFaces), isFalse());
}

- (void)testSuccessfullySettingCachedImageWithoutCenterFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    UIImage* testImage     = [UIImage new];

    [given([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    XCTestExpectation* completionExpectation = [self expectationWithDescription:@"completion block was called"];
    __block BOOL didSetImageSynchronously    = NO;

    BOOL didSetCachedImage =
        [self.imageView
         wmf_setCachedImageForMetadata:testMetadata
                               options:0
                         setImageBlock:^(UIImageView* imgView, UIImage* img, MWKImage* meta) {
        assertThat(imgView, is(self.imageView));
        assertThat(img, is(testImage));
        assertThat(meta, is(testMetadata));
        didSetImageSynchronously = YES;
    }
                            completion:^(BOOL finished) { [completionExpectation fulfill]; }
                       usingController:self.mockImageController];

    XCTAssertTrue(didSetImageSynchronously);

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    XCTAssertTrue(didSetCachedImage);

    WaitForExpectations();

    [MKTVerifyCount(self.mockImageController, never()) fetchImageWithURL:testURL];
}

- (void)testSuccessfullySettingCachedImageWithCenterFaces {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    testMetadata.allNormalizedFaceBounds = @[];
    UIImage* testImage = [UIImage new];

    [given([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    __block BOOL didSetImageSynchronously    = NO;
    XCTestExpectation* completionExpectation = [self expectationWithDescription:@"completion block was called"];

    BOOL didSetCachedImage =
        [self.imageView
         wmf_setCachedImageForMetadata:testMetadata
                               options:WMFImageOptionCenterFace
                         setImageBlock:^(UIImageView* imgView, UIImage* img, MWKImage* meta) {
        assertThat(imgView, is(self.imageView));
        assertThat(img, is(testImage));
        assertThat(meta, is(testMetadata));
        didSetImageSynchronously = YES;
    }
                            completion:^(BOOL finished) { [completionExpectation fulfill]; }
                       usingController:self.mockImageController];

    XCTAssertTrue(didSetImageSynchronously);

    XCTAssert(self.imageView.wmf_imageController == self.mockImageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    XCTAssertTrue(didSetCachedImage);

    WaitForExpectations();

    [MKTVerifyCount(self.mockImageController, never()) fetchImageWithURL:testURL];
}

- (void)testFailureToSetUncachedImage {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];

    [given([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:nil];

    // set imageController & imageMetadata here so we can verify they were set to `nil` when cached image fails to set
    self.imageView.wmf_imageController = mock([WMFImageController class]);
    self.imageView.wmf_imageMetadata   = [[MWKImage alloc] initWithArticle:self.dummyArticle
                                                                 sourceURL:[NSURL URLWithString:@"//foo"]];

    BOOL didSetCachedImage =
        [self.imageView
         wmf_setCachedImageForMetadata:testMetadata
                               options:0
                         setImageBlock:^(UIImageView* imgView, UIImage* img, MWKImage* meta) {
        XCTFail(@"Should not call setImageBlock when cached image fails to be set.");
    }
                            completion:^(BOOL finished) { XCTFail(@"Should not call completion when cached image fails to be set."); }
                       usingController:self.mockImageController];

    XCTAssertFalse(didSetCachedImage);

    XCTAssertNil(self.imageView.wmf_imageController,
                 @"Image controller should be set to nil even if we fail to set the cached image.");

    XCTAssertNil(self.imageView.wmf_imageController,
                 @"Image metadata should be set to nil even if we fail to set the cached image.");
}

- (void)testFailureToSetCachedImageWithoutFaceDetection {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    UIImage* testImage     = [UIImage new];

    [given([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    // set imageController & imageMetadata here so we can verify they were set to `nil` when cached image fails to set
    self.imageView.wmf_imageController = mock([WMFImageController class]);
    self.imageView.wmf_imageMetadata   = [[MWKImage alloc] initWithArticle:self.dummyArticle
                                                                 sourceURL:[NSURL URLWithString:@"//foo"]];

    BOOL didSetCachedImage =
        [self.imageView
         wmf_setCachedImageForMetadata:testMetadata
                               options:WMFImageOptionCenterFace
                         setImageBlock:^(UIImageView* imgView, UIImage* img, MWKImage* meta) {
        XCTFail(@"Should not call setImageBlock when cached image fails to be set.");
    }
                            completion:^(BOOL finished) { XCTFail(@"Should not call completion when cached image fails to be set."); }
                       usingController:self.mockImageController];

    XCTAssertFalse(didSetCachedImage);

    XCTAssertNil(self.imageView.wmf_imageController,
                 @"Image controller should be set to nil even if we fail to set the cached image.");

    XCTAssertNil(self.imageView.wmf_imageController,
                 @"Image metadata should be set to nil even if we fail to set the cached image.");
}

- (void)testShouldNotFetchCachedImage {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    UIImage* testImage     = [UIImage new];

    [given([self.mockImageController cachedImageInMemoryWithURL:testURL]) willReturn:testImage];

    __block BOOL didSetImageSynchronously    = NO;
    XCTestExpectation* completionExpectation = [self expectationWithDescription:@"completion block was called"];

    [self.imageView
     wmf_setImageFromMetadata:testMetadata
                      options:0
                    withBlock:^(UIImageView* imgView, UIImage* img, MWKImage* meta) {
        assertThat(imgView, is(self.imageView));
        assertThat(img, is(testImage));
        assertThat(meta, is(testMetadata));
        didSetImageSynchronously = YES;
    }
                   completion:^(BOOL finished) { [completionExpectation fulfill]; }
                      onError:^(NSError* err) { XCTFail(@"Error callback erroneously called with error %@", err); }
              usingController:self.mockImageController];

    XCTAssertTrue(didSetImageSynchronously);

    WaitForExpectations();

    [MKTVerifyCount(self.mockImageController, never()) fetchImageWithURL:anything()];
}

- (void)testShouldCallErrorCallbackWhenFetchFails {
    NSURL* testURL         = [NSURL URLWithString:@"http://test/request.png"];
    MWKImage* testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:testURL];
    NSError* testError     = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil];

    [given([self.mockImageController fetchImageWithURL:testURL])
     willReturn:[AnyPromise promiseWithValue:testError]];

    XCTestExpectation* didCallError = [self expectationWithDescription:@"completion block was called"];

    [self.imageView
     wmf_setImageFromMetadata:testMetadata
                      options:0
                    withBlock:^(UIImageView* imgView, UIImage* img, MWKImage* meta) {
        XCTFail(@"Should not invoke setImageBlock on error");
    }
                   completion:^(BOOL finished) { XCTFail(@"Should not invoke completion on error."); }
                      onError:^(NSError* err) {
        assertThat(err, is(testError));
        [didCallError fulfill];
    }
              usingController:self.mockImageController];

    WaitForExpectations();
}

@end
