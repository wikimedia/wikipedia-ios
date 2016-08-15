//
//  NSURLExtrasTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NSURL+WMFExtras.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

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
        [@[ dummyURLWithExtension(@"png"),
            dummyURLWithExtension(@"PNG") ] valueForKey:WMF_SAFE_KEYPATH(NSURL.new, wmf_mimeTypeForExtension)];
    assertThat(testURLMimeTypes, everyItem(is(@"image/png")));
}

- (void)testMimeTypeWithJPEGExtension {
    NSArray *testURLMimeTypes =
        [@[ dummyURLWithExtension(@"jpg"),
            dummyURLWithExtension(@"jpeg"),
            dummyURLWithExtension(@"JPG"),
            dummyURLWithExtension(@"JPEG") ] valueForKey:WMF_SAFE_KEYPATH(NSURL.new, wmf_mimeTypeForExtension)];
    assertThat(testURLMimeTypes, everyItem(is(@"image/jpeg")));
}

- (void)testMimeTypeWithGIFExtension {
    NSArray *testURLMimeTypes =
        [@[ dummyURLWithExtension(@"gif"),
            dummyURLWithExtension(@"GIF") ] valueForKey:WMF_SAFE_KEYPATH(NSURL.new, wmf_mimeTypeForExtension)];
    assertThat(testURLMimeTypes, everyItem(is(@"image/gif")));
}

- (void)testPrependSchemeAddHTTPSToSchemelessURL {
    assertThat([[NSURL URLWithString:@"//foo.org/bar.jpg"] wmf_urlByPrependingSchemeIfSchemeless],
               is([NSURL URLWithString:@"https://foo.org/bar.jpg"]));
}

- (void)testPrependSchemeReturnsOriginalURLWithScheme {
    NSURL *urlWithScheme = [NSURL URLWithString:@"https://foo.org/bar"];
    // checking identity instead of equality to make sure we return the receiver
    XCTAssertTrue(urlWithScheme == [urlWithScheme wmf_urlByPrependingSchemeIfSchemeless]);
}

- (void)testSchemelessURLStringPreservesEverythingExceptSchemeAndColon {
    NSURL *urlWithScheme = [NSURL URLWithString:@"https://foo.org/bar"];
    assertThat([urlWithScheme wmf_schemelessURLString], is(@"//foo.org/bar"));
}

- (void)testSchemelessURLIsEqualToAbsoluteStringOfURLWithoutScheme {
    NSURL *urlWithoutScheme = [NSURL URLWithString:@"//foo.org/bar"];
    assertThat([urlWithoutScheme wmf_schemelessURLString], is(urlWithoutScheme.absoluteString));
}

@end
