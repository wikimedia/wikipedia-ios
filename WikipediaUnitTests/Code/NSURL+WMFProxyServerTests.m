#import <XCTest/XCTest.h>
#import "NSURL+WMFSchemeHandler.h"

@interface NSURL_WMFSchemeHandlerTests : XCTestCase

@end

@implementation NSURL_WMFSchemeHandlerTests

- (void)testImageProxyURLCreation {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080"];
    XCTAssert([[[url wmf_imageAppSchemeURLWithOriginalSrc:@"http://www.img.jpg"] absoluteString] isEqualToString:@"http://localhost:8080?originalSrc=http://www.img.jpg"]);
}

- (void)testImageProxyURLCreationWithPath {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/SOMEPATH"];
    XCTAssert([[[url wmf_imageAppSchemeURLWithOriginalSrc:@"http://www.img.jpg"] absoluteString] isEqualToString:@"http://localhost:8080/SOMEPATH?originalSrc=http://www.img.jpg"]);
}

- (void)testImageProxyURLCreationWithPathAndExistingQueryParameters {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/SOMEPATH?haha=chacha"];
    XCTAssert([[[url wmf_imageAppSchemeURLWithOriginalSrc:@"http://www.img.jpg"] absoluteString] isEqualToString:@"http://localhost:8080/SOMEPATH?haha=chacha&originalSrc=http://www.img.jpg"]);
}

- (void)testImageProxyURLExtractionSingleQueryParameter {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080?originalSrc=http://this.jpg"];
    XCTAssert([[[url wmf_imageAppSchemeOriginalSrcURL] absoluteString] isEqualToString:@"http://this.jpg"]);
}

- (void)testImageProxyURLExtractionWithMultipleQueryParameters {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080?key=value&originalSrc=http://this.jpg"];
    XCTAssert([[[url wmf_imageAppSchemeOriginalSrcURL] absoluteString] isEqualToString:@"http://this.jpg"]);
}

- (void)testImageProxyURLExtractionWithNoQueryParameters {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080"];
    XCTAssertNil([[url wmf_imageAppSchemeOriginalSrcURL] absoluteString]);
}

- (void)testImageProxyURLExtractionWithEmptyOriginalSrcValue {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080?originalSrc="];
    XCTAssert([[[url wmf_imageAppSchemeOriginalSrcURL] absoluteString] isEqualToString:@""]);
}

@end
