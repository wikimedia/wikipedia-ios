#import <XCTest/XCTest.h>
#import "WMFFaceDetectionCache.h"
#import "WMFTestFixtureUtilities.h"
#import "CIDetector+WMFFaceDetection.h"
#import "WMFAsyncTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"

@interface MWKImageFaceDetectionTests : WMFAsyncTestCase
@property (nonatomic, strong) MWKImage *image;
@property (nonatomic, strong) MWKArticle *dummyArticle;
@property (nonatomic, strong) MWKDataStore *dataStore;
@property (nonatomic, strong) WMFFaceDetectionCache *faceDetectionCache;
@end

@implementation MWKImageFaceDetectionTests

- (void)setUp {
    [super setUp];
    self.dataStore = [MWKDataStore temporaryDataStore];
    self.dummyArticle = [[MWKArticle alloc] initWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"foo"]
                                              dataStore:self.dataStore];
    self.faceDetectionCache = [[WMFFaceDetectionCache alloc] init];
}

#pragma mark - Serialization

/* TODO: replace these tests with tests which use `faceDetectionCache` (vs `focalRects` which is deprecated, as is `didDetectFaces` and `hasFaces`).

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
    XCTAssert([self.image.sourceURLString isEqualToString:sourceURL]);
    XCTAssertFalse(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
    XCTAssert([self.image.dataExport isEqual:testData]);
}

- (void)testDeserializedImageWithDetectionButNoFaces {
    NSDictionary *testData = @{
        @"focalRects": @[],
        @"sourceURL": @"foo"
    };
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:testData];
    XCTAssert(self.image.didDetectFaces);
    XCTAssertFalse(self.image.hasFaces);
    XCTAssertEqual(self.image.allNormalizedFaceBounds.count, 0);
    XCTAssert([[self.image dataExport] isEqual:testData]);
}

- (void)testDeserializedImageWithDetectedFaces {
    CGRect testRect = CGRectMake(1, 1, 10, 10);
    NSDictionary *testData = @{
        @"focalRects": @[NSStringFromCGRect(testRect)],
        @"sourceURL": @"foo"
    };
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle dict:testData];
    XCTAssert(self.image.didDetectFaces);
    XCTAssert(self.image.hasFaces);
    XCTAssert([self.image.allNormalizedFaceBounds isEqual:@[[NSValue valueWithCGRect:testRect]]]);
    XCTAssert(CGRectEqualToRect(self.image.firstFaceBounds, testRect));
    XCTAssert([self.image.dataExport isEqual:testData]);
}

#pragma mark - Detection

- (void)testShouldSetDidDetectFacesIfPassedNilFeatures {
    self.image = [[MWKImage alloc] initWithArticle:self.dummyArticle sourceURL:[NSURL URLWithString:@"foo"]];
    self.image.allNormalizedFaceBounds = nil;
    XCTAssert(self.image.didDetectFaces, @"Need to be able to handle cases where CIDetector passes nil.");
}

*/

@end
