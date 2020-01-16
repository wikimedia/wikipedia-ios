#import <XCTest/XCTest.h>
#import "NSURL+WMFSchemeHandler.h"

@interface NSURL_WMFSchemeHandlerTests : XCTestCase

@end

@implementation NSURL_WMFSchemeHandlerTests

- (void)testImageProxyURLCreation {
    XCTAssert([[[NSURL wmf_legacyAppSchemeURLForURLString:@"http://www.img.jpg"] absoluteString] isEqualToString:@"wmfapp://www.img.jpg"]);
}

- (void)testImageProxyURLCreationWithPath {
    XCTAssert([[[NSURL wmf_legacyAppSchemeURLForURLString:@"http://www.img.jpg/SOMEPATH"] absoluteString] isEqualToString:@"wmfapp://www.img.jpg/SOMEPATH"]);
}

- (void)testImageProxyURLCreationWithPathAndExistingQueryParameters {
    XCTAssert([[[NSURL wmf_legacyAppSchemeURLForURLString:@"http://www.img.jpg/SOMEPATH?haha=chacha"] absoluteString] isEqualToString:@"wmfapp://www.img.jpg/SOMEPATH?haha=chacha"]);
}

- (void)testImageProxyURLExtraction {
    NSURL *url = [NSURL URLWithString:@"wmfapp://this.jpg"];
    XCTAssert([[[url wmf_originalURLFromAppSchemeURL] absoluteString] isEqualToString:@"https://this.jpg"]);
}

- (void)testImageProxyURLExtractionWithMultipleQueryParameters {
    NSURL *url = [NSURL URLWithString:@"wmfapp://localhost:8080?key=value&originalSrc=http://this.jpg"];
    XCTAssert([[[url wmf_originalURLFromAppSchemeURL] absoluteString] isEqualToString:@"https://localhost:8080?key=value&originalSrc=http://this.jpg"]);
}

@end
