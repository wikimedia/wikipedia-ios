#import "WMFAsyncTestCase.h"
#import "UIImageView+WMFImageFetchingInternal.h"
#import "WMFFaceDetectionCache.h"
#import "Wikipedia-Swift.h"
#import "MWKArticle.h"
#import "MWKImage.h"
#import <Nocilla/Nocilla.h>

@interface UIImageView_MWKImageTests : WMFAsyncTestCase

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) MWKArticle *dummyArticle;
@property (nonatomic, strong) WMFImageController *imageController;
@property (nonatomic, strong) WMFFaceDetectionCache *faceDetectionCache;
@property (nonatomic, strong) NSURL *testURL;
@property (nonatomic, copy) NSData *stubbedData;
@property (nonatomic, strong) UIImage *image;

@end

@implementation UIImageView_MWKImageTests

- (void)setUp {
    [super setUp];

    self.imageView = [UIImageView new];
    NSURL *dummyURL = [NSURL wmf_URLWithDomain:@"wikipedia.org" language:@"en" title:@"Foo" fragment:nil];
    self.dummyArticle = [[MWKArticle alloc] initWithURL:dummyURL
                                              dataStore:nil];
    self.imageController = [WMFImageController sharedInstance];
    self.faceDetectionCache = [[WMFFaceDetectionCache alloc] init];

    NSString *testURLString = @"http://test/request.png";
    self.testURL = [NSURL URLWithString:testURLString];

    UIImage *testImage = [UIImage imageNamed:@"wikipedia-wordmark"];
    self.stubbedData = UIImagePNGRepresentation(testImage);

    [[LSNocilla sharedInstance] start];
    stubRequest(@"GET", self.testURL.absoluteString).andReturnRawResponse(self.stubbedData);
}

- (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [[UIImageView faceDetectionCache] clearCache];
    [super tearDown];
}

#pragma mark - Fetch Tests

- (void)testSuccessfullySettingImageFromMetadataWithCenterFaces {
    MWKImage *testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:self.testURL];

    [self.imageView wmf_setImageController:self.imageController];

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata
        detectFaces:YES
        failure:^(NSError *error) {
            XCTFail(@"Error callback erroneously called with error %@", error);
            [promiseExpectation fulfill];
        }
        success:^{
            [promiseExpectation fulfill];
        }];

    XCTAssert(self.imageView.wmf_imageController == self.imageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    XCTAssert(self.imageView.image != nil);

    // XCTAssert(testMetadata.didDetectFaces);

    // XCTAssert([[UIImageView faceDetectionCache] imageRequiresFaceDetection:testMetadata] == NO,
    //          @"Face detection should have ran.");
}

- (void)testSuccessfullySettingImageFromURLWithCenterFaces {
    [self.imageView wmf_setImageController:self.imageController];

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:self.testURL
        detectFaces:YES
        failure:^(NSError *error) {
            XCTFail(@"Error callback erroneously called with error %@", error);
            [promiseExpectation fulfill];
        }
        success:^{
            [promiseExpectation fulfill];
        }];

    XCTAssert(self.imageView.wmf_imageController == self.imageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageURL == self.testURL,
              @"Image url should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    XCTAssert([[UIImageView faceDetectionCache] imageAtURLRequiresFaceDetection:self.testURL] == NO, @"Face detection should have ran.");

    XCTAssert(self.imageView.image != nil);
}

- (void)testSuccessfullySettingImageFromMetadataWithoutCenterFaces {
    MWKImage *testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:self.testURL];

    [self.imageView wmf_setImageController:self.imageController];

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata
        detectFaces:NO
        failure:^(NSError *error) {
            XCTFail(@"Error callback erroneously called with error %@", error);
            [promiseExpectation fulfill];
        }
        success:^{
            [promiseExpectation fulfill];
        }];

    XCTAssert(self.imageView.wmf_imageController == self.imageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    XCTAssert(self.imageView.image != nil);

    // XCTAssertFalse(testMetadata.didDetectFaces);

    // XCTAssert([[UIImageView faceDetectionCache] imageRequiresFaceDetection:testMetadata] == YES,
    //          @"Face detection should NOT have ran.");
}

- (void)testSuccessfullySettingImageFromURLWithoutCenterFaces {
    [self.imageView wmf_setImageController:self.imageController];

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:self.testURL
        detectFaces:NO
        failure:^(NSError *error) {
            XCTFail(@"Error callback erroneously called with error %@", error);
            [promiseExpectation fulfill];
        }
        success:^{
            [promiseExpectation fulfill];
        }];

    XCTAssert(self.imageView.wmf_imageController == self.imageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageURL == self.testURL,
              @"Image url should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    XCTAssert([[UIImageView faceDetectionCache] imageAtURLRequiresFaceDetection:self.testURL] == YES, @"Face detection should NOT have ran.");

    XCTAssert(self.imageView.image != nil);
}

- (void)testSuccessfullySettingCachedImageWithoutCenterFaces {
    MWKImage *testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:self.testURL];

    XCTestExpectation *expectation = [self expectationWithDescription:@"wait for download"];
    [self.imageController fetchImageWithURL:self.testURL
        failure:^(NSError *_Nonnull error) {
            XCTAssert(false);
            [expectation fulfill];
        }
        success:^(WMFImageDownload *_Nonnull download) {
            self.image = download.image.staticImage;
            [expectation fulfill];
        }];

    WaitForExpectations();

    [self.imageView wmf_setImageController:self.imageController];

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata
        detectFaces:NO
        failure:^(NSError *error) {
            XCTFail(@"Error callback erroneously called with error %@", error);
            [promiseExpectation fulfill];
        }
        success:^{
            [promiseExpectation fulfill];
        }];

    XCTAssert(self.imageView.wmf_imageController == self.imageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    XCTAssert(self.imageView.image == self.image);

    // XCTAssertFalse(testMetadata.didDetectFaces);

    // XCTAssert([[UIImageView faceDetectionCache] imageRequiresFaceDetection:testMetadata] == YES,
    //          @"Face detection should NOT have ran.");
}

- (void)testSuccessfullySettingCachedImageURLWithoutCenterFaces {
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait for download"];
    [self.imageController fetchImageWithURL:self.testURL
        failure:^(NSError *_Nonnull error) {
            XCTAssert(false);
            [expectation fulfill];
        }
        success:^(WMFImageDownload *_Nonnull download) {
            self.image = download.image.staticImage;
            [expectation fulfill];
        }];

    WaitForExpectations();

    [self.imageView wmf_setImageController:self.imageController];

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:self.testURL
        detectFaces:NO
        failure:^(NSError *error) {
            XCTFail(@"Error callback erroneously called with error %@", error);
            [promiseExpectation fulfill];
        }
        success:^{
            [promiseExpectation fulfill];
        }];

    XCTAssert(self.imageView.wmf_imageController == self.imageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageURL == self.testURL,
              @"Image url should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    XCTAssert([[UIImageView faceDetectionCache] imageAtURLRequiresFaceDetection:self.testURL] == YES, @"Face detection should NOT have ran.");

    XCTAssert(self.imageView.image == self.image);
}

- (void)testSuccessfullySettingCachedImageWithCenterFaces {
    MWKImage *testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:self.testURL];

    XCTestExpectation *expectation = [self expectationWithDescription:@"wait for download"];
    [self.imageController fetchImageWithURL:self.testURL
        failure:^(NSError *_Nonnull error) {
            XCTAssert(false);
            [expectation fulfill];
        }
        success:^(WMFImageDownload *_Nonnull download) {
            self.image = download.image.staticImage;
            [expectation fulfill];
        }];

    WaitForExpectations();

    [self.imageView wmf_setImageController:self.imageController];

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata
        detectFaces:YES
        failure:^(NSError *error) {
            XCTFail(@"Error callback erroneously called with error %@", error);
            [promiseExpectation fulfill];
        }
        success:^{
            [promiseExpectation fulfill];
        }];

    XCTAssert(self.imageView.wmf_imageController == self.imageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageMetadata == testMetadata,
              @"Image metadata should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    XCTAssert(self.imageView.image == self.image);

    // XCTAssert(testMetadata.didDetectFaces);

    // XCTAssert([[UIImageView faceDetectionCache] imageRequiresFaceDetection:testMetadata] == NO,
    //          @"Face detection should have ran.");
}

- (void)testSuccessfullySettingCachedImageURLWithCenterFaces {
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait for download"];
    [self.imageController fetchImageWithURL:self.testURL
        failure:^(NSError *_Nonnull error) {
            XCTAssert(false);
            [expectation fulfill];
        }
        success:^(WMFImageDownload *_Nonnull download) {
            self.image = download.image.staticImage;
            [expectation fulfill];
        }];

    WaitForExpectations();

    [self.imageView wmf_setImageController:self.imageController];

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:self.testURL
        detectFaces:YES
        failure:^(NSError *error) {
            XCTFail(@"Error callback erroneously called with error %@", error);
            [promiseExpectation fulfill];
        }
        success:^{
            [promiseExpectation fulfill];
        }];

    XCTAssert(self.imageView.wmf_imageController == self.imageController,
              @"Image controller should be set immediately after the method is called so it can be cancelled.");

    XCTAssert(self.imageView.wmf_imageURL == self.testURL,
              @"Image url should be set immediately after the method is called so it can be checked & cancelled.");

    WaitForExpectations();

    XCTAssert([[UIImageView faceDetectionCache] imageAtURLRequiresFaceDetection:self.testURL] == NO, @"Face detection should have ran.");

    XCTAssert(self.imageView.image == self.image);
}

- (void)testFailureToSetUncachedImageWithFetchError {
    self.testURL = [NSURL URLWithString:@"http://test/bogus.png"];
    stubRequest(@"GET", self.testURL.absoluteString).andFailWithError([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]);
    MWKImage *testMetadata = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:self.testURL];

    self.imageView.wmf_imageController = self.imageController;

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithMetadata:testMetadata
        detectFaces:YES
        failure:^(NSError *error) {
            XCTAssert(true);
            [promiseExpectation fulfill];
        }
        success:^{
            XCTFail(@"Promise fullfilled erroneously with url %@", [self.testURL description]);
        }];

    WaitForExpectations();
}

- (void)testFailureToSetUncachedImageURLWithFetchError {
    self.testURL = [NSURL URLWithString:@"http://test/bogus.png"];
    stubRequest(@"GET", self.testURL.absoluteString).andFailWithError([NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]);

    self.imageView.wmf_imageController = self.imageController;

    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.imageView wmf_setImageWithURL:self.testURL
        detectFaces:YES
        failure:^(NSError *error) {
            XCTAssert(true);
            [promiseExpectation fulfill];
        }
        success:^{
            XCTFail(@"Promise fullfilled erroneously with url %@", [self.testURL description]);
        }];

    WaitForExpectations();
}

- (void)testFailureOfImageCacheToDetectFacesOfImageWithNoFaces {
    XCTestExpectation *promiseExpectation = [self expectationWithDescription:@"promise was fullfilled"];

    [self.faceDetectionCache detectFaceBoundsInImage:[UIImage new]
        onGPU:YES
        URL:self.testURL
        failure:^(NSError *error) {
            XCTFail();
            [promiseExpectation fulfill];
        }
        success:^(NSValue *value) {
            XCTAssert(CGRectIsEmpty([value CGRectValue]), @"Bounds should be null since the image has no data");
            [promiseExpectation fulfill];
        }];

    WaitForExpectations();

    XCTAssertFalse([self.faceDetectionCache imageAtURLRequiresFaceDetection:self.testURL]);
    XCTAssert([self.faceDetectionCache faceBoundsForURL:self.testURL] == nil);
}

@end
