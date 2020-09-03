#import <XCTest/XCTest.h>
#import "NSURL+WMFExtras.h"

static NSURL *dummyURLWithExtension(NSString *extension) {
    return [NSURL URLWithString:[@"http://foo.org/bar." stringByAppendingString:extension]];
}

@interface NSURLExtrasTests : XCTestCase

@end

@implementation NSURLExtrasTests

- (void)testOptionalURLReturnsNilForNilString {
    XCTAssertNil([NSURL wmf_optionalURLWithString:nil]);
}

- (void)testOptionalURLReturnsNilForEmptyString {
    XCTAssertNil([NSURL wmf_optionalURLWithString:@""]);
}

- (void)testMimeTypeWithPNGExtension {
    NSArray *testURLMimeTypes =
        [@[dummyURLWithExtension(@"png"),
           dummyURLWithExtension(@"PNG")] valueForKey:WMF_SAFE_KEYPATH(NSURL.new, wmf_mimeTypeForExtension)];
    for (NSString *mimeType in testURLMimeTypes){
        XCTAssertEqualObjects(mimeType, @"image/png");
    }
}

- (void)testMimeTypeWithJPEGExtension {
    NSArray *testURLMimeTypes =
        [@[dummyURLWithExtension(@"jpg"),
           dummyURLWithExtension(@"jpeg"),
           dummyURLWithExtension(@"JPG"),
           dummyURLWithExtension(@"JPEG")] valueForKey:WMF_SAFE_KEYPATH(NSURL.new, wmf_mimeTypeForExtension)];
    for (NSString *mimeType in testURLMimeTypes){
        XCTAssertEqualObjects(mimeType, @"image/jpeg");
    }
}

- (void)testMimeTypeWithGIFExtension {
    NSArray *testURLMimeTypes =
        [@[dummyURLWithExtension(@"gif"),
           dummyURLWithExtension(@"GIF")] valueForKey:WMF_SAFE_KEYPATH(NSURL.new, wmf_mimeTypeForExtension)];
    for (NSString *mimeType in testURLMimeTypes){
        XCTAssertEqualObjects(mimeType, @"image/gif");
    }
}

- (void)testPrependSchemeAddHTTPSToSchemelessURL {
    XCTAssertEqualObjects([[NSURL URLWithString:@"//foo.org/bar.jpg"] wmf_urlByPrependingSchemeIfSchemeless], [NSURL URLWithString:@"https://foo.org/bar.jpg"]);
}

- (void)testPrependSchemeReturnsOriginalURLWithScheme {
    NSURL *urlWithScheme = [NSURL URLWithString:@"https://foo.org/bar"];
    // checking identity instead of equality to make sure we return the receiver
    XCTAssertTrue(urlWithScheme == [urlWithScheme wmf_urlByPrependingSchemeIfSchemeless]);
}

- (void)testSchemelessURLStringPreservesEverythingExceptSchemeAndColon {
    NSURL *urlWithScheme = [NSURL URLWithString:@"https://foo.org/bar"];
    XCTAssertEqualObjects([urlWithScheme wmf_schemelessURLString], @"//foo.org/bar");
}

- (void)testSchemelessURLIsEqualToAbsoluteStringOfURLWithoutScheme {
    NSURL *urlWithoutScheme = [NSURL URLWithString:@"//foo.org/bar"];
    XCTAssertEqualObjects([urlWithoutScheme wmf_schemelessURLString], urlWithoutScheme.absoluteString);
}

@end
