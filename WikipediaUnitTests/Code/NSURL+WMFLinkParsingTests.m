//
//  NSURL+WMFLinkParsingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NSURL+WMFLinkParsing.h"
#import "NSString+WMFPageUtilities.h"
#import "MWKTitle.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface NSURL_WMFLinkParsingTests : XCTestCase

@end

@implementation NSURL_WMFLinkParsingTests

- (void)testCitationURL {
    XCTAssertTrue(([[NSURL URLWithString:[NSString stringWithFormat:@"#%@-0", WMFCitationFragmentSubstring]] wmf_isCitation]));
}

- (void)testURLWithoutFragmentIsNotCitation {
    XCTAssertFalse([[NSURL URLWithString:@"/wiki/Foo"] wmf_isCitation]);
}

- (void)testURLWithFragmentNotContainingCitaitonSubstringIsNotCitation {
    XCTAssertFalse([[NSURL URLWithString:@"/wiki/Foo#bar"] wmf_isCitation]);
}

- (void)testRelativeInternalLink {
    XCTAssertTrue([[NSURL URLWithString:@"/wiki/Foo"] wmf_isInternalLink]);
}

- (void)testAbsoluteInternalLink {
    XCTAssertTrue([[NSURL URLWithString:@"https://en.wikipedia.org/wiki/Foo"] wmf_isInternalLink]);
}

- (void)testAbsoluteInternalLinkWithOtherComponents {
    XCTAssertTrue([[NSURL URLWithString:@"https://en.wikipedia.org/wiki/Foo?query=&string=value#fragment"] wmf_isInternalLink]);
}

- (void)testRelativeExternalLink {
    XCTAssertFalse([[NSURL URLWithString:@"/Foo"] wmf_isInternalLink]);
}

- (void)testAbsoluteExternalLink {
    XCTAssertFalse([[NSURL URLWithString:@"https://www.foo.com/bar"] wmf_isInternalLink]);
}

- (void)testInternalLinkPath {
    NSString* testPath = @"foo/bar";
    NSURL* testURL     = [[NSURL URLWithString:WMFInternalLinkPathPrefix]
                      URLByAppendingPathComponent:testPath];
    assertThat([testURL wmf_internalLinkPath], is(testPath));
}

- (void)testInternalLinkPathForURLExcludesFragmentAndQuery {
    NSString* testPath                     = @"foo/bar";
    NSString* testPathWithQueryAndFragment = [WMFInternalLinkPathPrefix stringByAppendingFormat:@"%@?baz#buz", testPath];
    assertThat([[NSURL URLWithString:testPathWithQueryAndFragment] wmf_internalLinkPath], is(testPath));
}

@end
