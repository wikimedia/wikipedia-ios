#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFFaceDetectionCache.h"
#import "WMFTestFixtureUtilities.h"
#import "CIDetector+WMFFaceDetection.h"
#import "WMFAsyncTestCase.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKImageFaceDetectionTests : WMFAsyncTestCase
@property (nonatomic, strong) MWKImage *image;
@property (nonatomic, strong) MWKArticle *dummyArticle;
@property (nonatomic, strong) MWKDataStore *mockDataStore;
@property (nonatomic, strong) WMFFaceDetectionCache *faceDetectionCache;
@end

@implementation MWKImageFaceDetectionTests

- (void)setUp {
    [super setUp];
    self.mockDataStore = MKTMock([MWKDataStore class]);
    self.dummyArticle = [[MWKArticle alloc] initWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"foo"]
                                              dataStore:self.mockDataStore];
    self.faceDetectionCache = [[WMFFaceDetectionCache alloc] init];
}

#pragma mark - Serialization

- (void)testInitialStateShouldIndicateNoDetectionOrFaces {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:[NSURL URLWithString:@"foo"]];
    XCTAssertFalse(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
    XCTAssertNil(self.image.allNormalizedFaceBounds);
}

- (void)testSerializationOfImageWithoutDetection {
    NSString *sourceURL = @"foo";
    NSDictionary *testData = NSDictionaryOfVariableBindings(sourceURL);
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:testData];
    assertThat(self.image.sourceURLString, is(sourceURL));
    XCTAssertFalse(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
    assertThat([self.image dataExport], is(testData));
}

- (void)testDeserializedImageWithDetectionButNoFaces {
    NSDictionary *testData = @{
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
    CGRect testRect = CGRectMake(1, 1, 10, 10);
    NSDictionary *testData = @{
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

- (void)testShouldSetDidDetectFacesIfPassedNilFeatures {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:[NSURL URLWithString:@"foo"]];
    self.image.allNormalizedFaceBounds = nil;
    XCTAssertTrue(self.image.didDetectFaces, @"Need to be able to handle cases where CIDetector passes nil.");
}

@end
