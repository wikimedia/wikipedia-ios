#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NSURL+WMFProxyServer.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface NSURL_WMFProxyServerTests : XCTestCase

@end

@implementation NSURL_WMFProxyServerTests

- (void)testImageProxyURLCreation {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080"];
    assertThat([[url wmf_imageProxyURLWithOriginalSrc:@"http://www.img.jpg"] absoluteString], is(@"http://localhost:8080?originalSrc=http://www.img.jpg"));
}

- (void)testImageProxyURLCreationWithPath {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/SOMEPATH"];
    assertThat([[url wmf_imageProxyURLWithOriginalSrc:@"http://www.img.jpg"] absoluteString], is(@"http://localhost:8080/SOMEPATH?originalSrc=http://www.img.jpg"));
}

- (void)testImageProxyURLCreationWithPathAndExistingQueryParameters {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/SOMEPATH?haha=chacha"];
    assertThat([[url wmf_imageProxyURLWithOriginalSrc:@"http://www.img.jpg"] absoluteString], is(@"http://localhost:8080/SOMEPATH?haha=chacha&originalSrc=http://www.img.jpg"));
}

- (void)testImageProxyURLExtractionSingleQueryParameter {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080?originalSrc=http://this.jpg"];
    assertThat([[url wmf_imageProxyOriginalSrcURL] absoluteString], is(@"http://this.jpg"));
}

- (void)testImageProxyURLExtractionWithMultipleQueryParameters {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080?key=value&originalSrc=http://this.jpg"];
    assertThat([[url wmf_imageProxyOriginalSrcURL] absoluteString], is(@"http://this.jpg"));
}

- (void)testImageProxyURLExtractionWithNoQueryParameters {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080"];
    assertThat([[url wmf_imageProxyOriginalSrcURL] absoluteString], is(nilValue()));
}

- (void)testImageProxyURLExtractionWithEmptyOriginalSrcValue {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080?originalSrc="];
    assertThat([[url wmf_imageProxyOriginalSrcURL] absoluteString], is(@""));
}

@end
